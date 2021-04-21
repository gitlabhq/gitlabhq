# frozen_string_literal: true

module Gitlab
  class Throttle
    DEFAULT_RATE_LIMITING_RESPONSE_TEXT = 'Retry later'

    def self.settings
      Gitlab::CurrentSettings.current_application_settings
    end

    # Returns true if we should use the Admin Area protected paths throttle
    def self.protected_paths_enabled?
      self.settings.throttle_protected_paths_enabled?
    end

    def self.omnibus_protected_paths_present?
      Rack::Attack.throttles.key?('protected paths')
    end

    def self.bypass_header
      env_value = ENV['GITLAB_THROTTLE_BYPASS_HEADER']
      return unless env_value.present?

      "HTTP_#{env_value.upcase.tr('-', '_')}"
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

    def self.unauthenticated_packages_api_options
      limit_proc = proc { |req| settings.throttle_unauthenticated_packages_api_requests_per_period }
      period_proc = proc { |req| settings.throttle_unauthenticated_packages_api_period_in_seconds.seconds }

      { limit: limit_proc, period: period_proc }
    end

    def self.authenticated_packages_api_options
      limit_proc = proc { |req| settings.throttle_authenticated_packages_api_requests_per_period }
      period_proc = proc { |req| settings.throttle_authenticated_packages_api_period_in_seconds.seconds }

      { limit: limit_proc, period: period_proc }
    end

    def self.rate_limiting_response_text
      (settings.rate_limiting_response_text.presence || DEFAULT_RATE_LIMITING_RESPONSE_TEXT) + "\n"
    end
  end
end
