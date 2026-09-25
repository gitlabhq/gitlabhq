# frozen_string_literal: true

module Ci
  class PlayBridgeService < ::BaseService
    include Ci::JobRateLimitable

    # @rate_limit - false for internal callers that must never be throttled
    def initialize(project, user = nil, params = {})
      super
      @rate_limit = params.fetch(:rate_limit, true)
    end

    def execute(bridge)
      throttled_response = rate_limited_response(bridge)
      return throttled_response if throttled_response

      check_access!(bridge)

      job = Ci::EnqueueJobService.new(bridge, current_user: current_user).execute

      ServiceResponse.success(payload: { job: job })
    end

    private

    def rate_limit?
      @rate_limit
    end

    # Shares the play buckets with builds: a played trigger job creates a downstream pipeline.
    def rate_limited_response(bridge)
      return unless Feature.enabled?(:rate_limit_job_play, project)

      job_rate_limited_response(
        bridge, key: :job_play, per_project_key: :job_play_per_project, message: 'Job play rate limit exceeded'
      )
    end

    def check_access!(bridge)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_job, bridge)
    end
  end
end

Ci::PlayBridgeService.prepend_mod_with('Ci::PlayBridgeService')
