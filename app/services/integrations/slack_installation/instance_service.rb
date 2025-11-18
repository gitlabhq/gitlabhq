# frozen_string_literal: true

module Integrations
  module SlackInstallation
    class InstanceService < BaseService
      private

      def redirect_uri
        slack_auth_admin_application_settings_slack_url
      end

      def installation_alias
        SlackIntegration::INSTANCE_ALIAS
      end

      def fallback_alias; end

      def authorized?
        current_user.can_admin_all_resources?
      end

      def find_or_create_integration!
        GitlabSlackApplication
          .for_instance
          .first_or_create!(organization_id: params[:organization_id]) # rubocop:disable CodeReuse/ActiveRecord: -- legacy use
      end
    end
  end
end
