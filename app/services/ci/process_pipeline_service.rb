# frozen_string_literal: true

module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    def execute(pipeline, trigger_build_ids = nil)
      @pipeline = pipeline

      update_retried

      success =
        stage_indexes_of_created_processables.flat_map do |index|
          process_stage(index)
        end.any?

      # we evaluate dependent needs,
      # only when the another job has finished
      success = process_builds_with_needs(trigger_build_ids) || success

      @pipeline.update_status

      success
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

    def process_builds_with_needs(trigger_build_ids)
      return false unless trigger_build_ids.present?
      return false unless Feature.enabled?(:ci_dag_support, project)

      # rubocop: disable CodeReuse/ActiveRecord
      trigger_build_names = pipeline.statuses
        .where(id: trigger_build_ids)
        .select(:name)
      # rubocop: enable CodeReuse/ActiveRecord

      created_processables
        .with_needs(trigger_build_names)
        .find_each
        .map(&method(:process_build_with_needs))
        .any?
    end

    def process_build_with_needs(build)
      current_status = status_for_build_needs(build.needs.map(&:name))

      return unless HasStatus::COMPLETED_STATUSES.include?(current_status)

      Gitlab::OptimisticLocking.retry_lock(build) do |subject|
        Ci::ProcessBuildService.new(project, @user)
          .execute(subject, current_status)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def status_for_prior_stages(index)
      pipeline.builds.where('stage_idx < ?', index).latest.status || 'success'
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def status_for_build_needs(needs)
      pipeline.builds.where(name: needs).latest.status || 'success'
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
