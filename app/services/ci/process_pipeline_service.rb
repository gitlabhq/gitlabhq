# frozen_string_literal: true

module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      update_retried

      new_builds =
        stage_indexes_of_created_processables.map do |index|
          process_stage(index)
        end

      @pipeline.update_status

      new_builds.flatten.any?
    end

    private

    def process_stage(index)
      current_status = status_for_prior_stages(index)

      return if HasStatus::BLOCKED_STATUS.include?(current_status)

      if HasStatus::COMPLETED_STATUSES.include?(current_status)
        created_processables_in_stage(index).select do |build|
          Gitlab::OptimisticLocking.retry_lock(build) do |subject|
            Ci::ProcessBuildService.new(project, @user)
              .execute(build, current_status)
          end
        end
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def status_for_prior_stages(index)
      pipeline.builds.where('stage_idx < ?', index).latest.status || 'success'
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def stage_indexes_of_created_processables
      created_processables.order(:stage_idx).pluck(Arel.sql('DISTINCT stage_idx'))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def created_processables_in_stage(index)
      created_processables.where(stage_idx: index)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def created_processables
      pipeline.processables.created
    end

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
