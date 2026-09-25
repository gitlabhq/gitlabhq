# frozen_string_literal: true

module Ci
  # Per-user rate limiting for job actions (retry, play), checked before any other
  # step of the service so a rejected call still costs a request.
  #
  # Expects the including service to expose `current_user`, `project` and `rate_limit?`
  # (false for internal callers that must never be throttled). The feature flag check
  # stays in the service, because the flag key must be a literal.
  module JobRateLimitable
    private

    # Returns a throttled ServiceResponse, or nil when the call may proceed.
    def job_rate_limited_response(job, key:, per_project_key:, message:)
      return unless rate_limit? && current_user
      return unless job_rate_limit_throttled?(job, key, per_project_key)

      log_job_rate_limited(job, message)

      ServiceResponse.error(
        message: ::Gitlab::ApplicationRateLimiter.throttled_error_message,
        reason: :rate_limited,
        payload: { job: job, reason: :rate_limited }
      )
    end

    # Short-circuit on the per-job limit so an already-blocked caller does not keep
    # consuming the per-project budget for the project's other jobs.
    def job_rate_limit_throttled?(job, key, per_project_key)
      return true if ::Gitlab::ApplicationRateLimiter.throttled?(
        key, scope: { user: current_user, ci_build: job }
      )

      ::Gitlab::ApplicationRateLimiter.throttled?(
        per_project_key, scope: { user: current_user, project: project }
      )
    end

    def log_job_rate_limited(job, message)
      Gitlab::AppJsonLogger.info(
        Labkit::Fields::CLASS_NAME => self.class.to_s,
        message: message,
        Labkit::Fields::GL_PROJECT_ID => project.id,
        job_id: job.id,
        Labkit::Fields::GL_USER_ID => current_user.id,
        **Gitlab::ApplicationContext.current
      )
    end
  end
end
