# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module DependencyProxyHelpers
        REGISTRY_BASE_URLS = {
          npm: 'https://registry.npmjs.org/',
          pypi: 'https://pypi.org/simple/'
        }.freeze

        APPLICATION_SETTING_NAMES = {
          npm: 'npm_package_requests_forwarding',
          pypi: 'pypi_package_requests_forwarding'
        }.freeze

        def redirect_registry_request(forward_to_registry, package_type, options)
          if forward_to_registry && redirect_registry_request_available?(package_type)
            ::Gitlab::Tracking.event(self.options[:for].name, "#{package_type}_request_forward")
            redirect(registry_url(package_type, options))
          else
            yield
          end
        end

        def registry_url(package_type, options)
          base_url = REGISTRY_BASE_URLS[package_type]

          raise ArgumentError, "Can't build registry_url for package_type #{package_type}" unless base_url

          case package_type
          when :npm
            "#{base_url}#{options[:package_name]}"
          when :pypi
            "#{base_url}#{options[:package_name]}/"
          end
        end

        def redirect_registry_request_available?(package_type)
          application_setting_name = APPLICATION_SETTING_NAMES[package_type]

          raise ArgumentError, "Can't find application setting for package_type #{package_type}" unless application_setting_name

          ::Gitlab::CurrentSettings
            .current_application_settings
            .attributes
            .fetch(application_setting_name, false)
        end
      end
    end
  end
end
