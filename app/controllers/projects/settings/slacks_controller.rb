module Projects
  module Settings
    class SlacksController < Projects::ApplicationController
      before_action :handle_oauth_error, only: :slack_auth
      before_action :authorize_admin_project!

      def slack_auth
        result = Projects::SlackApplicationInstallService.new(project, current_user, params).execute

        if result[:status] == :error
          flash[:alert] = result[:message]
        end

        redirect_to_service_page
      end

      def destroy
        service = project.gitlab_slack_application_service
        service.slack_integration.destroy

        redirect_to_service_page
      end

      private

      def redirect_to_service_page
        redirect_to edit_project_service_path(
          project,
          project.gitlab_slack_application_service || project.build_gitlab_slack_application_service
        )
      end

      def handle_oauth_error
        if params[:error] == 'access_denied'
          flash[:alert] = 'Access denied'
          redirect_to_service_page
        end
      end
    end
  end
end
