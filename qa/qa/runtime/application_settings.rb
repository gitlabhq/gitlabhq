# frozen_string_literal: true

module QA
  module Runtime
    class ApplicationSettings
      class << self
        include Support::Api

        APPLICATION_SETTINGS_PATH = '/application/settings'

        # Set a GitLab application setting
        # Example:
        #   #set({ allow_local_requests_from_web_hooks_and_services: true })
        #   #set(allow_local_requests_from_web_hooks_and_services: true)
        # https://docs.gitlab.com/ee/api/settings.html
        def set_application_settings(**application_settings)
          @original_application_settings = get_application_settings

          QA::Runtime::Logger.info("Setting application settings: #{application_settings}")
          r = put(Runtime::API::Request.new(api_client, APPLICATION_SETTINGS_PATH).url, **application_settings)
          raise "Couldn't set application settings #{application_settings.inspect}" unless r.code == QA::Support::Api::HTTP_STATUS_OK
        end

        def get_application_settings
          parse_body(get(Runtime::API::Request.new(api_client, APPLICATION_SETTINGS_PATH).url))
        end

        def restore_application_settings(*application_settings_keys)
          set_application_settings(@original_application_settings.slice(*application_settings_keys))
        end

        private

        def api_client
          @api_client ||= Runtime::API::Client.as_admin
        rescue API::Client::AuthorizationError => e
          raise "Administrator access is required to set application settings. #{e.message}"
        end
      end
    end
  end
end
