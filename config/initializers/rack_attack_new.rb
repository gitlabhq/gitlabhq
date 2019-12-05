# Specs for this file can be found on:
# * spec/lib/gitlab/throttle_spec.rb
# * spec/requests/rack_attack_global_spec.rb
module Gitlab::Throttle
  def self.settings
    Gitlab::CurrentSettings.current_application_settings
  end

  # Returns true if we should use the Admin Area protected paths throttle
  def self.protected_paths_enabled?
    return false if should_use_omnibus_protected_paths?

    self.settings.throttle_protected_paths_enabled?
  end

  # To be removed in 13.0: https://gitlab.com/gitlab-org/gitlab/issues/29952
  def self.should_use_omnibus_protected_paths?
    !Settings.rack_attack.admin_area_protected_paths_enabled &&
      self.omnibus_protected_paths_present?
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
  # Order conditions by how expensive they are:
  # 1. The most expensive is the `req.unauthenticated?` and
  #    `req.authenticated_user_id` as it performs an expensive
  #    DB/Redis query to validate the request
  # 2. Slightly less expensive is the need to query DB/Redis
  #    to unmarshal settings (`Gitlab::Throttle.settings`)
  #
  # We deliberately skip `/-/health|liveness|readiness`
  # from Rack Attack as they need to always be accessible
  # by Load Balancer and additional measure is implemented
  # (token and whitelisting) to prevent abuse.
  throttle('throttle_unauthenticated', Gitlab::Throttle.unauthenticated_options) do |req|
    if !req.should_be_skipped? &&
        Gitlab::Throttle.settings.throttle_unauthenticated_enabled &&
        req.unauthenticated?
      req.ip
    end
  end

  throttle('throttle_authenticated_api', Gitlab::Throttle.authenticated_api_options) do |req|
    if req.api_request? &&
        Gitlab::Throttle.settings.throttle_authenticated_api_enabled
      req.authenticated_user_id([:api])
    end
  end

  throttle('throttle_authenticated_web', Gitlab::Throttle.authenticated_web_options) do |req|
    if req.web_request? &&
        Gitlab::Throttle.settings.throttle_authenticated_web_enabled
      req.authenticated_user_id([:api, :rss, :ics])
    end
  end

  throttle('throttle_unauthenticated_protected_paths', Gitlab::Throttle.protected_paths_options) do |req|
    if req.post? &&
        !req.should_be_skipped? &&
        req.protected_path? &&
        Gitlab::Throttle.protected_paths_enabled? &&
        req.unauthenticated?
      req.ip
    end
  end

  throttle('throttle_authenticated_protected_paths_api', Gitlab::Throttle.protected_paths_options) do |req|
    if req.post? &&
        req.api_request? &&
        req.protected_path? &&
        Gitlab::Throttle.protected_paths_enabled?
      req.authenticated_user_id([:api])
    end
  end

  throttle('throttle_authenticated_protected_paths_web', Gitlab::Throttle.protected_paths_options) do |req|
    if req.post? &&
        req.web_request? &&
        req.protected_path? &&
        Gitlab::Throttle.protected_paths_enabled?
      req.authenticated_user_id([:api, :rss, :ics])
    end
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

    def health_check_request?
      path =~ %r{^/-/(health|liveness|readiness)}
    end

    def should_be_skipped?
      api_internal_request? || health_check_request?
    end

    def web_request?
      !api_request? && !health_check_request?
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
