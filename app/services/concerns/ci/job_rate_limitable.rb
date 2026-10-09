# frozen_string_literal: true

module Ci
  # Per-user rate limiting for job actions (retry, play, erase), checked before
  # any other step of the service so a rejected call still costs a request.
  #
  # Expects the including service to expose `current_user`, `project` and `rate_limit?`
  # (false for internal callers that must never be throttled). The feature flag check
  # stays in the service, because the flag key must be a literal.
  module JobRateLimitable
    private

    # Returns a throttled ServiceResponse, or nil when the call may proceed.
    def job_rate_limited_response(job, key:, per_project_key:, log_message:)
      return unless rate_limit? && current_user

      limit = throttled_job_limit(job, key, per_project_key)
      return unless limit

      log_job_rate_limited(job, log_message, limit)

      ServiceResponse.error(
        message: ::Gitlab::ApplicationRateLimiter.throttled_error_message,
        reason: :rate_limited,
        payload: { job: job, reason: :rate_limited }
      )
    end

    # Returns the key of the limit that fired, or nil. Short-circuit on the per-job limit
    # so an already-blocked caller does not keep consuming the per-project budget for the
    # project's other jobs.
    def throttled_job_limit(job, key, per_project_key)
      return key if ::Gitlab::ApplicationRateLimiter.throttled?(
        key, scope: { user: current_user, ci_build: job }
      )

      return per_project_key if ::Gitlab::ApplicationRateLimiter.throttled?(
        per_project_key, scope: { user: current_user, project: project }
      )

      nil
    end

    def log_job_rate_limited(job, log_message, limit)
      Gitlab::AppJsonLogger.info(
        Labkit::Fields::CLASS_NAME => self.class.to_s,
        message: log_message,
        rate_limit: limit.to_s,
        Labkit::Fields::GL_PROJECT_ID => project.id,
        job_id: job.id,
        Labkit::Fields::GL_USER_ID => current_user.id,
        **Gitlab::ApplicationContext.current
      )
    end
  end
end
