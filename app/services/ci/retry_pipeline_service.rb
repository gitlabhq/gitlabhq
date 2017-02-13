module Ci
  class RetryPipelineService
    include Gitlab::Allowable

    def initialize(pipeline, user)
      @pipeline = pipeline
      @user = user
    end

    def execute
      unless can?(@user, :update_pipeline, @pipeline)
        raise Gitlab::Access::AccessDeniedError
      end

      ##
      # Reprocess builds in subsequent stages if any
      #
      # TODO, refactor.
      #
      @pipeline.builds
        .where('stage_idx > ?', resume_stage.index)
        .failed_or_canceled.find_each do |build|
          Ci::RetryBuildService.new(build, @user).reprocess!
        end

      ##
      # Retry builds in the first unsuccessful stage
      #
      resume_stage.builds.failed_or_canceled.find_each do |build|
        Ci::Build.retry(build, @user)
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
