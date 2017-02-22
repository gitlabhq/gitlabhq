module Ci
  class RetryPipelineService < ::BaseService
    def execute(pipeline)
      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      pipeline.builds.failed_or_canceled.find_each do |build|
        next unless build.retryable?

        pipeline.mark_as_processable_after_stage(build.stage_idx)

        Ci::RetryBuildService.new(project, current_user)
          .reprocess(build)
      end

      MergeRequests::AddTodoWhenBuildFailsService
        .new(project, current_user)
        .close_all(pipeline)

      pipeline.process!
    end
  end
end
