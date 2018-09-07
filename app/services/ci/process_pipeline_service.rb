# frozen_string_literal: true

module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      update_retried

      new_builds =
        stage_indexes_of_created_builds.map do |index|
          process_stage(index)
        end

      @pipeline.update_status

      new_builds.flatten.any?
    end

    private

    def process_stage(index)
      current_status = status_for_prior_stages(index)

      return if HasStatus::BLOCKED_STATUS == current_status

      if HasStatus::COMPLETED_STATUSES.include?(current_status)
        created_builds_in_stage(index).select do |build|
          Gitlab::OptimisticLocking.retry_lock(build) do |subject|
            process_build(subject, current_status)
          end
        end
      end
    end

    def process_build(build, current_status)
      if valid_statuses_for_when(build.when).include?(current_status)
        if build.delayed?
          build.schedule
        elsif build.action?
          build.actionize
        else
          enqueue_build(build)
        end
        true
      else
        build.skip
        false
      end
    end

    def valid_statuses_for_when(value)
      case value
      when 'on_success'
        %w[success skipped]
      when 'on_failure'
        %w[failed]
      when 'always'
        %w[success failed skipped]
      when 'manual'
        %w[success skipped]
      when /^in/
        %w[success skipped]
      else
        []
      end
    end

    def status_for_prior_stages(index)
      pipeline.builds.where('stage_idx < ?', index).latest.status || 'success'
    end

    def stage_indexes_of_created_builds
      created_builds.order(:stage_idx).pluck('distinct stage_idx')
    end

    def created_builds_in_stage(index)
      created_builds.where(stage_idx: index)
    end

    def created_builds
      pipeline.builds.created
    end

    # This method is for compatibility and data consistency and should be removed with 9.3 version of GitLab
    # This replicates what is db/post_migrate/20170416103934_upate_retried_for_ci_build.rb
    # and ensures that functionality will not be broken before migration is run
    # this updates only when there are data that needs to be updated, there are two groups with no retried flag
    def update_retried
      # find the latest builds for each name
      latest_statuses = pipeline.statuses.latest
        .group(:name)
        .having('count(*) > 1')
        .pluck('max(id)', 'name')

      # mark builds that are retried
      pipeline.statuses.latest
        .where(name: latest_statuses.map(&:second))
        .where.not(id: latest_statuses.map(&:first))
        .update_all(retried: true) if latest_statuses.any?
    end

    def enqueue_build(build)
      Ci::EnqueueBuildService.new(project, @user).execute(build)
    end
  end
end
