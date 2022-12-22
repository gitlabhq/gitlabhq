# frozen_string_literal: true

# == CheckRateLimit
#
# Controller concern that checks if the rate limit for a given action is throttled by calling the
# Gitlab::ApplicationRateLimiter class. If the action is throttled for the current user, the request
# will be logged and an error message will be rendered with a Too Many Requests response status.
# See lib/api/helpers/rate_limiter.rb for API version
module CheckRateLimit
  def check_rate_limit!(key, scope:, redirect_back: false, **options)
    return unless Gitlab::ApplicationRateLimiter.throttled_request?(request, current_user, key, scope: scope, **options)

    return yield if block_given?

    message = _('This endpoint has been requested too many times. Try again later.')

    if redirect_back
      redirect_back_or_default(options: { alert: message })
    else
      render plain: message, status: :too_many_requests
    end
  end
end
