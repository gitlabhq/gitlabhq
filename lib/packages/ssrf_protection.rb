# frozen_string_literal: true

module Packages
  class SsrfProtection
    def self.params_for(package)
      return {} unless package
      return {} unless package_feature_enabled?(package)

      {
        ssrf_filter: true,
        allow_localhost: allow_localhost?,
        allowed_endpoints: ObjectStoreSettings.enabled_endpoint_uris
      }
    end

    def self.allow_localhost?
      Gitlab.dev_or_test_env? || Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
    end

    def self.package_feature_enabled?(package)
      case package.package_type.to_sym
      when :generic
        Feature.enabled?(:generic_package_registry_ssrf_protection, package.project)
      # Future package types can be added here
      # when :npm
      #   Feature.enabled?(:npm_package_registry_ssrf_protection, package.project)
      else
        false
      end
    end
  end
end
