# frozen_string_literal: true

module API
  module Helpers
    module RateLimiter
      def check_rate_limit!(key, scope, users_allowlist = nil)
        if rate_limiter.throttled?(key, scope: scope, users_allowlist: users_allowlist)
          log_request(key)
          render_exceeded_limit_error!
        end
      end

      private

      def rate_limiter
        ::Gitlab::ApplicationRateLimiter
      end

      def render_exceeded_limit_error!
        render_api_error!({ error: _('This endpoint has been requested too many times. Try again later.') }, 429)
      end

      def log_request(key)
        rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)
      end
    end
  end
end
