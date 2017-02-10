module Ci
  class RetryBuildService
    include Gitlab::Allowable

    def initialize(build, user)
      @build = build
      @user = user
      @pipeline = build.pipeline
    end

    def retry!
      unless can?(@user, :update_build, @build)
        raise Gitlab::Access::AccessDeniedError
      end

      clone_build.tap do |new_build|
        new_build.enqueue!

        MergeRequests::AddTodoWhenBuildFailsService
          .new(@build.project, @user)
          .close(new_build)

        @pipeline.mark_as_processable_after_stage(@build.stage_idx)
      end
    end

    private

    def clone_build
      Ci::Build.create(
        ref: @build.ref,
        tag: @build.tag,
        options: @build.options,
        commands: @build.commands,
        tag_list: @build.tag_list,
        project: @build.project,
        pipeline: @build.pipeline,
        name: @build.name,
        allow_failure: @build.allow_failure,
        stage: @build.stage,
        stage_idx: @build.stage_idx,
        trigger_request: @build.trigger_request,
        yaml_variables: @build.yaml_variables,
        when: @build.when,
        environment: @build.environment,
        user: @user)
    end
  end
end
