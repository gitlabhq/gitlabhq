# frozen_string_literal: true

module Admin
  class SlacksController < Admin::ApplicationController
    include ::Integrations::SlackControllerSettings

    private

    def integration
      @integration ||= Integrations::GitlabSlackApplication.for_instance.first
    end

    def redirect_to_integration_page
      redirect_to edit_admin_application_settings_integration_path(
        integration || Integrations::GitlabSlackApplication.for_instance.new
      )
    end

    def installation_service
      Integrations::SlackInstallation::InstanceService.new(current_user: current_user, params: params.permit(:code))
    end
  end
end
