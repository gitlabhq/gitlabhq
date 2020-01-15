# frozen_string_literal: true

module Ci
  class ProcessPipelineService
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute(trigger_build_ids = nil)
      update_retried

      Ci::PipelineProcessing::LegacyProcessingService
        .new(pipeline)
        .execute(trigger_build_ids)
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
  end
end
