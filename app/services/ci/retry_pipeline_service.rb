module Ci
  class RetryPipelineService < ::BaseService
    def execute(pipeline)
      @pipeline = pipeline

      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      ##
      # Reprocess builds in subsequent stages
      #
      pipeline.builds
        .after_stage(resume_stage.index)
        .failed_or_canceled.find_each do |build|
          Ci::RetryBuildService
            .new(project, current_user)
            .reprocess(build)
        end

      ##
      # Mark skipped builds as processable again
      #
      pipeline.mark_as_processable_after_stage(resume_stage.index)

      ##
      # Retry builds in the first unsuccessful stage
      #
      resume_stage.builds.failed_or_canceled.find_each do |build|
        Ci::RetryBuildService
          .new(project, current_user)
          .retry(build)
      end
    end

    private

    def resume_stage
      @resume_stage ||= @pipeline.stages.find do |stage|
        stage.failed? || stage.canceled?
      end
    end
  end
end
