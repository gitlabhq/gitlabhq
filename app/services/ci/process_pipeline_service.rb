# frozen_string_literal: true

module Ci
  class ProcessPipelineService
    include Gitlab::Utils::StrongMemoize

    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute(trigger_build_ids = nil)
      update_retried

      success = process_stages_without_needs

      # we evaluate dependent needs,
      # only when the another job has finished
      success = process_builds_with_needs(trigger_build_ids) || success

      @pipeline.update_status

      success
    end

    private

    def process_stages_without_needs
      stage_indexes_of_created_processables_without_needs.flat_map do |index|
        process_stage_without_needs(index)
      end.any?
    end

    def process_stage_without_needs(index)
      current_status = status_for_prior_stages(index)

      return unless HasStatus::COMPLETED_STATUSES.include?(current_status)

      created_processables_in_stage_without_needs(index).find_each.select do |build|
        process_build(build, current_status)
      end.any?
    end

    def process_builds_with_needs(trigger_build_ids)
      return false unless trigger_build_ids.present?
      return false unless Feature.enabled?(:ci_dag_support, project, default_enabled: true)

      # we find processables that are dependent:
      # 1. because of current dependency,
      trigger_build_names = pipeline.processables.latest
        .for_ids(trigger_build_ids).names

      # 2. does not have builds that not yet complete
      incomplete_build_names = pipeline.processables.latest
        .incomplete.names

      # Each found processable is guaranteed here to have completed status
      created_processables
        .with_needs(trigger_build_names)
        .without_needs(incomplete_build_names)
        .find_each
        .map(&method(:process_build_with_needs))
        .any?
    end

    def process_build_with_needs(build)
      current_status = status_for_build_needs(build.needs.map(&:name))

      return unless HasStatus::COMPLETED_STATUSES.include?(current_status)

      process_build(build, current_status)
    end

    def process_build(build, current_status)
      Gitlab::OptimisticLocking.retry_lock(build) do |subject|
        Ci::ProcessBuildService.new(project, build.user)
          .execute(subject, current_status)
      end
    end

    def status_for_prior_stages(index)
      pipeline.processables.status_for_prior_stages(index)
    end

    def status_for_build_needs(needs)
      pipeline.processables.status_for_names(needs)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def stage_indexes_of_created_processables_without_needs
      created_processables_without_needs.order(:stage_idx)
        .pluck(Arel.sql('DISTINCT stage_idx'))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def created_processables_in_stage_without_needs(index)
      created_processables_without_needs
        .with_preloads
        .for_stage(index)
    end

    def created_processables_without_needs
      if Feature.enabled?(:ci_dag_support, project, default_enabled: true)
        pipeline.processables.created.without_needs
      else
        pipeline.processables.created
      end
    end

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

    def project
      pipeline.project
    end
  end
end
