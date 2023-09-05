# frozen_string_literal: true

module QA
  module Runtime
    # TODO: Ideally this should be changed to a normal class due to now being able to override what api client is used
    #
    class ApplicationSettings
      class << self
        include Support::API

        APPLICATION_SETTINGS_PATH = '/application/settings'

        # Set a GitLab application setting
        # Example:
        #   #set({ allow_local_requests_from_web_hooks_and_services: true })
        #   #set(allow_local_requests_from_web_hooks_and_services: true)
        # https://docs.gitlab.com/ee/api/settings.html
        def set_application_settings(api_client: admin_api_client, **application_settings)
          @original_application_settings = get_application_settings(api_client: api_client)

          QA::Runtime::Logger.info("Setting application settings: #{application_settings}")
          r = put(Runtime::API::Request.new(api_client, APPLICATION_SETTINGS_PATH).url, **application_settings)
          return if r.code == QA::Support::API::HTTP_STATUS_OK

          body = parse_body(r)
          raise("Couldn't set application settings #{application_settings.inspect}, code: '#{r.code}', body: #{body}")
        end

        # Get a single application setting
        #
        # @param setting [Symbol] the name of the setting to get
        # @param api_client [Runtime::API::Client] the API client representing the admin user who will get the setting
        # @return [String]
        def get_application_setting(setting, api_client: admin_api_client)
          get_application_settings(api_client: api_client).fetch(setting)
        end

        def get_application_settings(api_client: admin_api_client)
          parse_body(get(Runtime::API::Request.new(api_client, APPLICATION_SETTINGS_PATH).url))
        end

        # TODO: This class probably needs to be refactored because this method relies on original settings to have been
        # populated sometime in the past and there is no guarantee original settings instance variable is still valid
        def restore_application_settings(...)
          set_application_settings(**@original_application_settings.slice(...))
        end

        # Enable the application setting that allows requests from local services to the GitLab instance
        #
        # @return [Void]
        def enable_local_requests
          set_application_settings(allow_local_requests_from_web_hooks_and_services: true)
        end

        # Disables the application setting that allows local requests
        #
        # @return [Void]
        def disable_local_requests
          set_application_settings(allow_local_requests_from_web_hooks_and_services: false)
        end

        private

        def admin_api_client
          @admin_api_client ||= Runtime::API::Client.as_admin
        rescue API::Client::AuthorizationError => e
          raise "Administrator access is required to set application settings. #{e.message}"
        end
      end
    end
  end
end
