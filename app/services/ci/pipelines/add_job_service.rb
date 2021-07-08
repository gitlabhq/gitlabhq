# frozen_string_literal: true

module Ci
  module Pipelines
    class AddJobService
      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline

        raise ArgumentError, "Pipeline must be persisted for this service to be used" unless @pipeline.persisted?
      end

      def execute!(job, &block)
        assign_pipeline_attributes(job)

        Ci::Pipeline.transaction do
          yield(job)

          job.update_older_statuses_retried! if Feature.enabled?(:ci_fix_commit_status_retried, @pipeline.project, default_enabled: :yaml)
        end

        ServiceResponse.success(payload: { job: job })
      rescue StandardError => e
        ServiceResponse.error(message: e.message, payload: { job: job })
      end

      private

      def assign_pipeline_attributes(job)
        job.pipeline = @pipeline
        job.project = @pipeline.project
        job.ref = @pipeline.ref
      end
    end
  end
end
