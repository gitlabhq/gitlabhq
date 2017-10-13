class Rack::Attack
  def self.settings
    Gitlab::CurrentSettings.current_application_settings
  end

  def self.throttle_unauthenticated_options
    limit_proc = proc { |req| settings.throttle_unauthenticated_requests_per_period }
    period_proc = proc { |req| settings.throttle_unauthenticated_period_in_seconds.seconds }
    { limit: limit_proc, period: period_proc }
  end

  def self.throttle_authenticated_api_options
    limit_proc = proc { |req| settings.throttle_authenticated_api_requests_per_period }
    period_proc = proc { |req| settings.throttle_authenticated_api_period_in_seconds.seconds }
    { limit: limit_proc, period: period_proc }
  end

  def self.throttle_authenticated_web_options
    limit_proc = proc { |req| settings.throttle_authenticated_web_requests_per_period }
    period_proc = proc { |req| settings.throttle_authenticated_web_period_in_seconds.seconds }
    { limit: limit_proc, period: period_proc }
  end

  throttle('throttle_unauthenticated', throttle_unauthenticated_options) do |req|
    settings.throttle_unauthenticated_enabled &&
      req.unauthenticated? &&
      req.ip
  end

  throttle('throttle_authenticated_api', throttle_authenticated_api_options) do |req|
    settings.throttle_authenticated_api_enabled &&
      req.api_request? &&
      req.authenticated_user_id
  end

  throttle('throttle_authenticated_web', throttle_authenticated_web_options) do |req|
    settings.throttle_authenticated_web_enabled &&
      req.web_request? &&
      req.authenticated_user_id
  end

  class Request
    def unauthenticated?
      !authenticated_user_id
    end

    def authenticated_user_id
      session_user_id || sessionless_user_id
    end

    def api_request?
      path.start_with?('/api')
    end

    def web_request?
      !api_request?
    end

    private

    def session_user_id
      Gitlab::Auth.find_session_user(self)&.id
    end

    def sessionless_user_id
      Gitlab::Auth.find_sessionless_user(self)&.id
    end
  end
end
