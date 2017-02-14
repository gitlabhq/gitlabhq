module Ci
  class RetryPipelineService < ::BaseService
    def execute(pipeline)
      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      each_build(pipeline.builds.failed_or_canceled) do |build|
        next unless build.retryable?

        Ci::RetryBuildService.new(project, current_user)
          .reprocess(build)
      end

      pipeline.process!
    end

    private

    def each_build(relation)
      Gitlab::OptimisticLocking.retry_lock(relation) do |builds|
        builds.find_each { |build| yield build }
      end
    end
  end
end
