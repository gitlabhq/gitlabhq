# frozen_string_literal: true

module Groups
  module Settings
    class SlacksController < Groups::ApplicationController
      before_action :authorize_admin_group!

      include ::Integrations::SlackControllerSettings

      layout 'group_settings'

      private

      def integration
        @integration ||= Integrations::GitlabSlackApplication.for_group(group).first
      end

      def redirect_to_integration_page
        redirect_to edit_group_settings_integration_path(
          group, integration || Integrations::GitlabSlackApplication.for_group(group).new
        )
      end

      def installation_service
        Integrations::SlackInstallation::GroupService.new(group, current_user: current_user, params: params)
      end
    end
  end
end
