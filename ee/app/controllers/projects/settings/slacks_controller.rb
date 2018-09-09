module Projects
  module Settings
    class SlacksController < Projects::ApplicationController
      before_action :handle_oauth_error, only: :slack_auth
      before_action :check_oauth_state, only: :slack_auth
      before_action :authorize_admin_project!
      before_action :slack_integration, only: [:edit, :update]
      before_action :service, only: [:destroy, :edit, :update]

      layout 'project_settings'

      def slack_auth
        result = Projects::SlackApplicationInstallService.new(project, current_user, params).execute

        if result[:status] == :error
          flash[:alert] = result[:message]
        end

        redirect_to_service_page
      end

      def destroy
        slack_integration.destroy

        redirect_to_service_page
      end

      def edit
      end

      def update
        if slack_integration.update(slack_integration_params)
          flash[:notice] = 'The project alias was updated successfully'

          redirect_to_service_page
        else
          render :edit
        end
      end

      private

      def redirect_to_service_page
        redirect_to edit_project_service_path(
          project,
          project.gitlab_slack_application_service || project.build_gitlab_slack_application_service
        )
      end

      def check_oauth_state
        render_403 unless valid_authenticity_token?(session, params[:state])

        true
      end

      def handle_oauth_error
        if params[:error] == 'access_denied'
          flash[:alert] = 'Access denied'
          redirect_to_service_page
        end
      end

      def slack_integration
        @slack_integration ||= project.gitlab_slack_application_service.slack_integration
      end

      def service
        @service = project.gitlab_slack_application_service
      end

      def slack_integration_params
        params.require(:slack_integration).permit(:alias)
      end
    end
  end
end
