module Ci
  class ProcessPipelineService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      pipeline.builds.created.pluck('distinct stage_idx').sort.each do |index|
        return unless process_stage(index)
      end
    end

    private

    def process_stage(index)
      status = prior_builds(index)

      new_builds_for_stage(index).any? do |build|
        process_build(build, status)
      end
    end

    def process_build(build, status)
      if when_statuses(build.when).include?(status)
        build.queue
      else
        build.skip
      end
    end

    def when_statuses(value)
      case value
      when 'on_success', nil
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
      pipeline.builds.where('stage_idx < ?', index).latest.status
    end

    def new_builds_for_stage(index)
      pipeline.builds.created.where(stage_idx: index)
    end
  end
end
