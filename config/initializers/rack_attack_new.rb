module Gitlab::Throttle
  def self.settings
    Gitlab::CurrentSettings.current_application_settings
  end

  def self.protected_paths_enabled?
    !self.omnibus_protected_paths_present? &&
      self.settings.throttle_protected_paths_enabled?
  end

  def self.omnibus_protected_paths_present?
    Rack::Attack.throttles.key?('protected paths')
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

  def self.protected_paths_options
    limit_proc = proc { |req| settings.throttle_protected_paths_requests_per_period }
    period_proc = proc { |req| settings.throttle_protected_paths_period_in_seconds.seconds }

    { limit: limit_proc, period: period_proc }
  end
end

class Rack::Attack
  throttle('throttle_unauthenticated', Gitlab::Throttle.unauthenticated_options) do |req|
    Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
      req.unauthenticated? &&
      !req.should_be_skipped? &&
      req.ip
  end

  throttle('throttle_authenticated_api', Gitlab::Throttle.authenticated_api_options) do |req|
    Gitlab::Throttle.settings.throttle_authenticated_api_enabled &&
      req.api_request? &&
      req.authenticated_user_id([:api])
  end

  throttle('throttle_authenticated_web', Gitlab::Throttle.authenticated_web_options) do |req|
    Gitlab::Throttle.settings.throttle_authenticated_web_enabled &&
      req.web_request? &&
      req.authenticated_user_id([:api, :rss, :ics])
  end

  throttle('throttle_unauthenticated_protected_paths', Gitlab::Throttle.protected_paths_options) do |req|
    Gitlab::Throttle.protected_paths_enabled? &&
      req.unauthenticated? &&
      !req.should_be_skipped? &&
      req.protected_path? &&
      req.ip
  end

  throttle('throttle_authenticated_protected_paths_api', Gitlab::Throttle.protected_paths_options) do |req|
    Gitlab::Throttle.protected_paths_enabled? &&
      req.api_request? &&
      req.protected_path? &&
      req.authenticated_user_id([:api])
  end

  throttle('throttle_authenticated_protected_paths_web', Gitlab::Throttle.protected_paths_options) do |req|
    Gitlab::Throttle.protected_paths_enabled? &&
      req.web_request? &&
      req.protected_path? &&
      req.authenticated_user_id([:api, :rss, :ics])
  end

  class Request
    def unauthenticated?
      !authenticated_user_id([:api, :rss, :ics])
    end

    def authenticated_user_id(request_formats)
      Gitlab::Auth::RequestAuthenticator.new(self).user(request_formats)&.id
    end

    def api_request?
      path.start_with?('/api')
    end

    def api_internal_request?
      path =~ %r{^/api/v\d+/internal/}
    end

    def should_be_skipped?
      api_internal_request?
    end

    def web_request?
      !api_request?
    end

    def protected_path?
      !protected_path_regex.nil?
    end

    def protected_path_regex
      path =~ protected_paths_regex
    end

    private

    def protected_paths
      Gitlab::CurrentSettings.current_application_settings.protected_paths
    end

    def protected_paths_regex
      Regexp.union(protected_paths.map { |path| /\A#{Regexp.escape(path)}/ })
    end
  end
end

::Rack::Attack.extend_if_ee('::EE::Gitlab::Rack::Attack') # rubocop: disable Cop/InjectEnterpriseEditionModule
::Rack::Attack::Request.prepend_if_ee('::EE::Gitlab::Rack::Attack::Request')
