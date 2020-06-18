# frozen_string_literal: true

module Projects
  module Import
    class JiraController < Projects::ApplicationController
      before_action :authenticate_user!
      before_action :authorize_read_project!
      before_action :validate_jira_import_settings!

      def show
      end

      private

      def validate_jira_import_settings!
        Gitlab::JiraImport.validate_project_settings!(@project, user: current_user, configuration_check: false)

        true
      rescue Projects::ImportService::Error => e
        flash[:notice] = e.message
        redirect_to project_issues_path(@project)

        false
      end

      def jira_service
        strong_memoize(:jira_service) do
          @project.jira_service
        end
      end

      def jira_import_params
        params.permit(:jira_project_key)
      end
    end
  end
end
