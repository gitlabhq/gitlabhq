# frozen_string_literal: true

module Gitlab
  module RateLimitHelpers
    ARCHIVE_RATE_LIMIT_REACHED_MESSAGE = 'This archive has been requested too many times. Try again later.'
    ARCHIVE_RATE_ANONYMOUS_THRESHOLD = 100 # Allow 100 requests/min for anonymous users
    ARCHIVE_RATE_THROTTLE_KEY = :project_repositories_archive

    def archive_rate_limit_reached?(user, project)
      return false unless Feature.enabled?(:archive_rate_limit)

      key = ARCHIVE_RATE_THROTTLE_KEY

      if rate_limiter.throttled?(key, scope: [project, user], threshold: archive_rate_threshold_by_user(user))
        rate_limiter.log_request(request, "#{key}_request_limit".to_sym, user)

        return true
      end

      false
    end

    def archive_rate_threshold_by_user(user)
      if user
        nil # Use the defaults
      else
        ARCHIVE_RATE_ANONYMOUS_THRESHOLD
      end
    end

    def rate_limiter
      ::Gitlab::ApplicationRateLimiter
    end
  end
end
