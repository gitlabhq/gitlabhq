# frozen_string_literal: true

module Ci
  module PipelineCreation
    # Emits the `create_pipeline_from_commit` user-experience SLI for commit-driven
    # pipeline creations (push and merge_request_event). Invoked from the creation
    # workers so emission happens once per creation, after any Sidekiq retries settle.
    class ExperienceReporter
      EXPERIENCE_ID = :create_pipeline_from_commit
      IN_SCOPE_SOURCES = %w[push merge_request_event].freeze

      NON_CREATION_FAILURE_REASONS = (
        Enums::Ci::Pipeline.failure_reasons.keys -
        Enums::Ci::Pipeline.persistable_failure_reasons.keys -
        [:gitaly_unavailable]
      ).map(&:to_s).freeze

      class << self
        def report(pipeline:, source:, started_at:)
          emit(started_at: started_at, source: source, pipeline: pipeline, project_id: pipeline&.project_id) do
            bucket_for(pipeline)
          end
        end

        def report_error(source:, started_at:, project_id:)
          emit(started_at: started_at, source: source, pipeline: nil, project_id: project_id) { :error }
        end

        private

        def emit(started_at:, source:, pipeline:, project_id:)
          return unless IN_SCOPE_SOURCES.include?(source.to_s)
          return unless started_at

          error = case yield
                  when :success then false
                  when :error then true
                  else return
                  end

          Labkit::UserExperienceSli.observed(
            EXPERIENCE_ID,
            start_time: Time.zone.at(started_at),
            error: error,
            pipeline_source: source.to_s,
            creation_result: pipeline&.status,
            Labkit::Fields::GL_PROJECT_ID.to_sym => project_id,
            Labkit::Fields::GL_PIPELINE_ID.to_sym => pipeline&.id
          )
        rescue StandardError => e
          # Metrics emission must never raise into the caller's worker.
          Gitlab::ErrorTracking.track_exception(e)
        end

        def bucket_for(pipeline)
          return :no_emission if pipeline.nil? || pipeline.skipped?
          return :success if pipeline.persisted?
          return :no_emission if NON_CREATION_FAILURE_REASONS.include?(pipeline.failure_reason.to_s)

          :error
        end
      end
    end
  end
end
