# frozen_string_literal: true

module Projects
  module Settings
    class SlacksController < Projects::ApplicationController
      include ::Integrations::SlackControllerSettings

      before_action :authorize_admin_project!
      before_action :integration, only: [:edit, :update]
      before_action :slack_integration, only: [:edit, :update]

      layout 'project_settings'

      def edit; end

      def update
        if slack_integration.update(slack_integration_params)
          flash[:notice] = 'The project alias was updated successfully'

          redirect_to_integration_page
        else
          render :edit
        end
      end

      private

      def integration
        @integration ||= project.gitlab_slack_application_integration
      end

      def redirect_to_integration_page
        redirect_to edit_project_settings_integration_path(
          project, integration || project.build_gitlab_slack_application_integration
        )
      end

      def slack_integration_params
        params.require(:slack_integration).permit(:alias)
      end

      def installation_service
        ::Integrations::SlackInstallation::ProjectService.new(project, current_user: current_user, params: params)
      end
    end
  end
end
