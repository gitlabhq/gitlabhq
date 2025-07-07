# frozen_string_literal: true

module Integrations
  module SlackInstallation
    class InstanceService < BaseService
      private

      def redirect_uri
        slack_auth_admin_application_settings_slack_url
      end

      def installation_alias
        '_gitlab-instance'
      end

      def authorized?
        current_user.can_admin_all_resources?
      end

      def find_or_create_integration!
        GitlabSlackApplication.for_instance.first_or_create!
      end
    end
  end
end
