module Ci
  class RetryPipelineService < ::BaseService
    def execute(pipeline)
      @pipeline = pipeline

      unless can?(current_user, :update_pipeline, pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      pipeline.mark_as_processable_after_stage(resume_stage.index)

      retryable_builds_in_subsequent_stages do |build|
        Ci::RetryBuildService.new(project, current_user)
          .reprocess(build)
      end

      retryable_builds_in_first_unsuccessful_stage do |build|
        Ci::RetryBuildService.new(project, current_user)
          .retry(build)
      end
    end

    private

    def retryable_builds_in_subsequent_stages
      relation = @pipeline.builds
        .after_stage(resume_stage.index)
        .failed_or_canceled

      each_retryable_build_with_locking(relation) do |build|
        yield build
      end
    end

    def retryable_builds_in_first_unsuccessful_stage
      relation = resume_stage.builds.failed_or_canceled

      each_retryable_build_with_locking(relation) do |build|
        yield build
      end
    end

    def each_retryable_build_with_locking(relation)
      Gitlab::OptimisticLocking.retry_lock(relation) do |builds|
        builds.find_each do |build|
          next unless build.retryable?
          yield build
        end
      end
    end

    def resume_stage
      @resume_stage ||= @pipeline.stages.find do |stage|
        stage.failed? || stage.canceled?
      end
    end
  end
end
