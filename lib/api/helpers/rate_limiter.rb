# frozen_string_literal: true

module API
  module Helpers
    # == RateLimiter
    #
    # Helper that checks if the rate limit for a given endpoint is throttled by calling the
    # Gitlab::ApplicationRateLimiter module. If the action is throttled for the current user, the request
    # will be logged and an error message will be rendered with a Too Many Requests response status.
    # See app/controllers/concerns/check_rate_limit.rb for Rails controllers version
    module RateLimiter
      def check_rate_limit!(key, scope:, user: current_user, message: nil, **options)
        return unless Gitlab::ApplicationRateLimiter.throttled_request?(request, user, key, scope: scope, **options)

        # Execute custom logic if block is given
        yield if block_given?

        interval_value = options[:interval] || Gitlab::ApplicationRateLimiter.interval(key)
        error_message = message || _('This endpoint has been requested too many times. Try again later.')

        too_many_requests!({ error: error_message }, retry_after: interval_value)
      end

      def check_rate_limit_by_user_or_ip!(key, **options)
        check_rate_limit!(key, scope: current_user || ip_address, **options)
      end

      def mark_throttle!(key, scope:)
        Gitlab::ApplicationRateLimiter.throttled?(key, scope: scope)
      end
    end
  end
end
