module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    VALID_STATUSES = %w(success failed canceled skipped)

    def execute(pipeline)
      @pipeline = pipeline

      pipeline.builds.created.order(:stage_idx).pluck('distinct stage_idx').any? do |index|
        process_stage(index).any?
      end
    end

    private

    def process_stage(index)
      status = prior_builds(index)

      new_builds_for_stage(index).select do |build|
        process_build(build, status)
      end
    end

    def process_build(build, status)
      return false unless VALID_STATUSES.include?(status)

      if when_statuses(build.when || 'on_success').include?(status)
        build.queue
        true
      else
        build.skip
        false
      end
    end

    def when_statuses(value)
      case value
      when 'on_success'
        %w(success)
      when 'on_failure'
        %w(failed)
      when 'always'
        %w(success failed)
      else
        []
      end
    end

    def prior_builds(index)
      pipeline.builds.where('stage_idx < ?', index).latest.status  || 'success'
    end

    def new_builds_for_stage(index)
      pipeline.builds.created.where(stage_idx: index)
    end
  end
end
