module Ci
  class RetryPipelineService < ::BaseService
    include Gitlab::OptimisticLocking

    def execute(pipeline)
      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      pipeline.builds.latest.failed_or_canceled.find_each do |build|
        next unless build.retryable?

        Ci::RetryBuildService.new(project, current_user)
          .reprocess(build)
      end

      pipeline.builds.latest.skipped.find_each do |skipped|
        retry_optimistic_lock(skipped) { |build| build.process }
      end

      MergeRequests::AddTodoWhenBuildFailsService
        .new(project, current_user)
        .close_all(pipeline)

      pipeline.process!
    end
  end
end
