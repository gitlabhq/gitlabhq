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
        return if bypass_header_set?
        return unless rate_limiter.throttled?(key, scope: scope, **options)

        rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)

        return yield if block_given?

        render_api_error!({ error: _('This endpoint has been requested too many times. Try again later.') }, 429)
      end

      private

      def rate_limiter
        ::Gitlab::ApplicationRateLimiter
      end

      def bypass_header_set?
        ::Gitlab::Throttle.bypass_header.present? && request.get_header(Gitlab::Throttle.bypass_header) == '1'
      end
    end
  end
end
