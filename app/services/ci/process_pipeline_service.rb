# frozen_string_literal: true

module Ci
  class ProcessPipelineService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute(trigger_build_ids = nil, initial_process: false)
      update_retried
      ensure_scheduling_type_for_processables

      if Feature.enabled?(:ci_atomic_processing, pipeline.project)
        Ci::PipelineProcessing::AtomicProcessingService
          .new(pipeline)
          .execute
      else
        Ci::PipelineProcessing::LegacyProcessingService
          .new(pipeline)
          .execute(trigger_build_ids, initial_process: initial_process)
      end
    end

    private

    # This method is for compatibility and data consistency and should be removed with 9.3 version of GitLab
    # This replicates what is db/post_migrate/20170416103934_upate_retried_for_ci_build.rb
    # and ensures that functionality will not be broken before migration is run
    # this updates only when there are data that needs to be updated, there are two groups with no retried flag
    # rubocop: disable CodeReuse/ActiveRecord
    def update_retried
      # find the latest builds for each name
      latest_statuses = pipeline.statuses.latest
        .group(:name)
        .having('count(*) > 1')
        .pluck(Arel.sql('MAX(id)'), 'name')

      # mark builds that are retried
      pipeline.statuses.latest
        .where(name: latest_statuses.map(&:second))
        .where.not(id: latest_statuses.map(&:first))
        .update_all(retried: true) if latest_statuses.any?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Set scheduling type of processables if they were created before scheduling_type
    # data was deployed (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22246).
    # Given that this service runs multiple times during the pipeline
    # life cycle we need to ensure we populate the data once.
    # See more: https://gitlab.com/gitlab-org/gitlab/issues/205426
    def ensure_scheduling_type_for_processables
      lease = Gitlab::ExclusiveLease.new("set-scheduling-types:#{pipeline.id}", timeout: 1.hour.to_i)
      return unless lease.try_obtain

      pipeline.processables.populate_scheduling_type!
    end
  end
end
