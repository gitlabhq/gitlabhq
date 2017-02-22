module Ci
  class RetryPipelineService < ::BaseService
    def execute(pipeline)
      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      pipeline.builds.failed_or_canceled.tap do |builds|
        stage_idx = builds.order('stage_idx ASC')
          .pluck('DISTINCT stage_idx').first

        pipeline.mark_as_processable_after_stage(stage_idx)

        builds.find_each do |build|
          next unless build.retryable?

          Ci::RetryBuildService.new(project, current_user)
            .reprocess(build)
        end
      end

      MergeRequests::AddTodoWhenBuildFailsService
        .new(project, current_user)
        .close_all(pipeline)

      pipeline.process!
    end
  end
end
