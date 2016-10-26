module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      # This method will ensure that our pipeline does have all builds for all stages created
      if created_builds.empty?
        create_builds!
      end

      new_builds =
        stage_indexes_of_created_builds.map do |index|
          process_stage(index)
        end

      @pipeline.update_status

      new_builds.flatten.any?
    end

    private

    def create_builds!
      Ci::CreatePipelineBuildsService.new(project, current_user).execute(pipeline)
    end

    def process_stage(index)
      current_status = status_for_prior_stages(index)

      if HasStatus::COMPLETED_STATUSES.include?(current_status)
        created_builds_in_stage(index).select do |build|
          Gitlab::OptimisticLocking.retry_lock(build) do |build|
            process_build(build, current_status)
          end
        end
      end
    end

    def process_build(build, current_status)
      if valid_statuses_for_when(build.when).include?(current_status)
        r = build.enqueue
        true
      else
        r = build.skip
        false
      end
    end

    def valid_statuses_for_when(value)
      case value
      when 'on_success'
        %w[success]
      when 'on_failure'
        %w[failed]
      when 'always'
        %w[success failed]
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
