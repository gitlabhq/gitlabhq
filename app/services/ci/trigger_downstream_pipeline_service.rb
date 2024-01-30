# frozen_string_literal: true

module Ci
  # Enqueues the downstream pipeline worker.
  class TriggerDownstreamPipelineService
    # This is a temporary constant. It may be converted into an application setting
    # in the future. See https://gitlab.com/gitlab-org/gitlab/-/issues/425941.
    DOWNSTREAM_PIPELINE_TRIGGER_LIMIT_PER_PROJECT_USER_SHA = 50

    def initialize(bridge)
      @bridge = bridge
      @current_user = bridge.user
      @project = bridge.project
      @pipeline = bridge.pipeline
    end

    def execute
      unless bridge.triggers_downstream_pipeline?
        return ServiceResponse.success(message: 'Does not trigger a downstream pipeline')
      end

      if rate_limit_throttled? && enforce_rate_limit?
        bridge.drop!(:reached_downstream_pipeline_trigger_rate_limit)

        return ServiceResponse.error(message: 'Reached downstream pipeline trigger rate limit')
      end

      CreateDownstreamPipelineWorker.perform_async(bridge.id)

      ServiceResponse.success(message: 'Downstream pipeline enqueued')
    end

    private

    attr_reader :bridge, :current_user, :project, :pipeline

    def rate_limit_throttled?
      scope = [project, current_user, pipeline.sha]

      ::Gitlab::ApplicationRateLimiter.throttled?(:downstream_pipeline_trigger, scope: scope).tap do |throttled|
        create_throttled_log_entry if throttled
      end
    end

    def create_throttled_log_entry
      ::Gitlab::AppJsonLogger.info(
        class: self.class.name,
        project_id: project.id,
        current_user_id: current_user.id,
        pipeline_sha: pipeline.sha,
        subscription_plan: project.actual_plan_name,
        downstream_type: bridge.triggers_child_pipeline? ? 'child' : 'multi-project',
        message: 'Activated downstream pipeline trigger rate limit'
      )
    end

    def enforce_rate_limit?
      ::Feature.enabled?(:ci_rate_limit_downstream_pipelines, project, type: :gitlab_com_derisk)
    end
  end
end
