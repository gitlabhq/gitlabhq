module Gitlab::Throttle
  def self.settings
    Gitlab::CurrentSettings.current_application_settings
  end

  def self.unauthenticated_options
    limit_proc = proc { |req| settings.throttle_unauthenticated_requests_per_period }
    period_proc = proc { |req| settings.throttle_unauthenticated_period_in_seconds.seconds }
    { limit: limit_proc, period: period_proc }
  end

  def self.authenticated_api_options
    limit_proc = proc { |req| settings.throttle_authenticated_api_requests_per_period }
    period_proc = proc { |req| settings.throttle_authenticated_api_period_in_seconds.seconds }
    { limit: limit_proc, period: period_proc }
  end

  def self.authenticated_web_options
    limit_proc = proc { |req| settings.throttle_authenticated_web_requests_per_period }
    period_proc = proc { |req| settings.throttle_authenticated_web_period_in_seconds.seconds }
    { limit: limit_proc, period: period_proc }
  end
end

class Rack::Attack
  throttle('throttle_unauthenticated', Gitlab::Throttle.unauthenticated_options) do |req|
    Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
      req.unauthenticated? &&
      !req.api_internal_request? &&
      req.ip
  end

  throttle('throttle_authenticated_api', Gitlab::Throttle.authenticated_api_options) do |req|
    Gitlab::Throttle.settings.throttle_authenticated_api_enabled &&
      req.api_request? &&
      req.authenticated_user_id
  end

  throttle('throttle_authenticated_web', Gitlab::Throttle.authenticated_web_options) do |req|
    Gitlab::Throttle.settings.throttle_authenticated_web_enabled &&
      req.web_request? &&
      req.authenticated_user_id
  end

  class Request
    def unauthenticated?
      !authenticated_user_id
    end

    def authenticated_user_id
      Gitlab::Auth::RequestAuthenticator.new(self).user&.id
    end

    def api_request?
      path.start_with?('/api')
    end

    def api_internal_request?
      path =~ %r{^/api/v\d+/internal/}
    end

    def web_request?
      !api_request?
    end
  end
end
