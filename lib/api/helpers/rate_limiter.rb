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
      def check_rate_limit!(key, scope:, **options)
        return unless Gitlab::ApplicationRateLimiter.throttled_request?(
          request, current_user, key, scope: scope, **options
        )

        return yield if block_given?

        render_api_error!({ error: _('This endpoint has been requested too many times. Try again later.') }, 429)
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
