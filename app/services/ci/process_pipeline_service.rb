module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    COMPLETED_STATUSES = %w(success failed canceled skipped)

    def execute(pipeline)
      @pipeline = pipeline

      stages_indexes_for_created.any? do |index|
        process_stage(index).any?
      end
    end

    private

    def process_stage(index)
      status = status_for_prior_stages(index)

      builds_for_created_in_stage(index).select do |build|
        process_build(build, status)
      end
    end

    def process_build(build, status)
      return false unless COMPLETED_STATUSES.include?(status)

      if valid_statuses_for_when(build.when).include?(status)
        build.queue
        true
      else
        build.skip
        false
      end
    end

    def valid_statuses_for_when(value)
      case value
      when 'on_success', nil
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

    def builds_for_created_in_stage(index)
      pipeline.builds.created.where(stage_idx: index)
    end

    def stages_indexes_for_created
      pipeline.builds.created.order(:stage_idx).pluck('distinct stage_idx')
    end
  end
end
