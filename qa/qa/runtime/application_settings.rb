# frozen_string_literal: true

module QA
  module Runtime
    module ApplicationSettings
      extend self
      extend Support::Api

      APPLICATION_SETTINGS_PATH = '/application/settings'

      # Set a GitLab application setting
      # Example:
      #   #set({ allow_local_requests_from_web_hooks_and_services: true })
      #   #set(allow_local_requests_from_web_hooks_and_services: true)
      # https://docs.gitlab.com/ee/api/settings.html
      def set_application_settings(**application_settings)
        QA::Runtime::Logger.info("Setting application settings: #{application_settings}")
        r = put(Runtime::API::Request.new(api_client, APPLICATION_SETTINGS_PATH).url, **application_settings)
        raise "Couldn't set application settings #{application_settings.inspect}" unless r.code == QA::Support::Api::HTTP_STATUS_OK
      end

      def get_application_settings
        parse_body(get(Runtime::API::Request.new(api_client, APPLICATION_SETTINGS_PATH).url))
      end

      private

      def api_client
        @api_client ||= begin
          return Runtime::API::Client.new(:gitlab, personal_access_token: Runtime::Env.admin_personal_access_token) if Runtime::Env.admin_personal_access_token

          user = Resource::User.fabricate_via_api! do |user|
            user.username = Runtime::User.admin_username
            user.password = Runtime::User.admin_password
          end

          unless user.admin?
            raise "Administrator access is required to set application settings. User '#{user.username}' is not an administrator."
          end

          Runtime::API::Client.new(:gitlab, user: user)
        end
      end
    end
  end
end
