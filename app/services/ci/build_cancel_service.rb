# frozen_string_literal: true

module Ci
  class BuildCancelService
    include Ci::JobRateLimitable

    def initialize(build, user, force = false)
      @build = build
      @user = user
      @force = force
    end

    def execute
      throttled_response = rate_limited_response
      return throttled_response if throttled_response

      return forbidden unless allowed?
      return unprocessable_entity unless build.cancelable? || (force && allowed_to_force?)

      if force
        build.force_cancel
      else
        build.cancel
      end

      ServiceResponse.success(payload: build)
    end

    private

    attr_reader :build, :user, :force
    alias_method :current_user, :user

    def project
      build.project
    end

    def rate_limited_response
      return unless Feature.enabled?(:rate_limit_job_cancel, project)

      job_rate_limited_response(
        build, key: :job_cancel, per_project_key: :job_cancel_per_project, log_message: 'Job cancel rate limit exceeded'
      )
    end

    def allowed?
      user.can?(:cancel_build, build)
    end

    def allowed_to_force?
      build.force_cancelable? && user.can?(:force_cancel_build, build)
    end

    def forbidden
      ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
    end

    def unprocessable_entity
      ServiceResponse.error(message: 'Unprocessable entity', http_status: :unprocessable_entity)
    end
  end
end
