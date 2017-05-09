module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

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
        build.action? ? build.actionize : build.enqueue
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
  end
end
