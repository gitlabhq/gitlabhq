# frozen_string_literal: true

module Projects
  module Import
    class JiraController < Projects::ApplicationController
      before_action :authenticate_user!
      before_action :check_issues_available!
      before_action :authorize_read_project!
      before_action :authorize_admin_project!, only: [:import]

      def show
      end

      def import
        jira_project_key = jira_import_params[:jira_project_key]

        if jira_project_key.present?
          response = ::JiraImport::StartImportService.new(current_user, @project, jira_project_key).execute
          flash[:notice] = response.message if response.message.present?
        else
          flash[:alert] = 'No Jira project key has been provided.'
        end

        redirect_to project_import_jira_path(@project)
      end

      private

      def jira_import_params
        params.permit(:jira_project_key)
      end
    end
  end
end
