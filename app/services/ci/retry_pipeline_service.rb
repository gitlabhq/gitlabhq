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

      @pipeline.stages.each do |stage|
        stage.builds.failed_or_canceled.find_each do |build|
          Ci::Build.retry(build, @user)
        end
      end
    end
  end
end
