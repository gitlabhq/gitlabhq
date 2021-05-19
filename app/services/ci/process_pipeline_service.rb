# frozen_string_literal: true

module Ci
  class ProcessPipelineService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      increment_processing_counter

      update_retried

      Ci::PipelineProcessing::AtomicProcessingService
        .new(pipeline)
        .execute
    end

    def metrics
      @metrics ||= ::Gitlab::Ci::Pipeline::Metrics
    end

    private

    # This method is for compatibility and data consistency and should be removed with 9.3 version of GitLab
    # This replicates what is db/post_migrate/20170416103934_upate_retried_for_ci_build.rb
    # and ensures that functionality will not be broken before migration is run
    # this updates only when there are data that needs to be updated, there are two groups with no retried flag
    # rubocop: disable CodeReuse/ActiveRecord
    def update_retried
      return if Feature.enabled?(:ci_remove_update_retried_from_process_pipeline, pipeline.project, default_enabled: :yaml)

      # find the latest builds for each name
      latest_statuses = pipeline.latest_statuses
        .group(:name)
        .having('count(*) > 1')
        .pluck(Arel.sql('MAX(id)'), 'name')

      # mark builds that are retried
      if latest_statuses.any?
        updated_count = pipeline.latest_statuses
                          .where(name: latest_statuses.map(&:second))
                          .where.not(id: latest_statuses.map(&:first))
                          .update_all(retried: true)

        # This counter is temporary. It will be used to check whether if we still use this method or not
        # after setting correct value of `GenericCommitStatus#retried`.
        # More info: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50465#note_491657115
        if updated_count > 0
          Gitlab::AppJsonLogger.info(event: 'update_retried_is_used',
                                     project_id: pipeline.project.id,
                                     pipeline_id: pipeline.id)

          metrics.legacy_update_jobs_counter.increment
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def increment_processing_counter
      metrics.pipeline_processing_events_counter.increment
    end
  end
end
