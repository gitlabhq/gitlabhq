# frozen_string_literal: true

# == CheckRateLimit
#
# Controller concern that checks if the rate limit for a given action is throttled by calling the
# Gitlab::ApplicationRateLimiter class. If the action is throttled for the current user, the request
# will be logged and an error message will be rendered with a Too Many Requests response status.
module CheckRateLimit
  def check_rate_limit(key)
    return unless rate_limiter.throttled?(key, scope: current_user, users_allowlist: rate_limit_users_allowlist)

    rate_limiter.log_request(request, "#{key}_request_limit".to_sym, current_user)
    render plain: _('This endpoint has been requested too many times. Try again later.'), status: :too_many_requests
  end

  def rate_limiter
    ::Gitlab::ApplicationRateLimiter
  end

  def rate_limit_users_allowlist
    Gitlab::CurrentSettings.current_application_settings.notes_create_limit_allowlist
  end
end
