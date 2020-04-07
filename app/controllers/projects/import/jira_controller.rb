# frozen_string_literal: true

module Projects
  module Import
    class JiraController < Projects::ApplicationController
      before_action :jira_import_enabled?
      before_action :jira_integration_configured?

      def show
        return if Feature.enabled?(:jira_issue_import_vue, @project)

        unless @project.import_state&.in_progress?
          jira_client = @project.jira_service.client
          jira_projects = jira_client.Project.all

          if jira_projects.present?
            @jira_projects = jira_projects.map { |p| ["#{p.name} (#{p.key})", p.key] }
          else
            flash[:alert] = 'No projects have been returned from Jira. Please check your Jira configuration.'
          end
        end

        flash[:notice] = _("Import %{status}") % { status: @project.import_state.status } if @project.import_state.present? && !@project.import_state.none?
      end

      def import
        jira_project_key = jira_import_params[:jira_project_key]

        if jira_project_key.present?
          response = ::JiraImport::StartImportService.new(current_user, @project, jira_project_key).execute
          flash[:notice] = response.message if response.message.present?
        else
          flash[:alert] = 'No jira project key has been provided.'
        end

        redirect_to project_import_jira_path(@project)
      end

      private

      def jira_import_enabled?
        return if Feature.enabled?(:jira_issue_import, @project)

        redirect_to project_issues_path(@project)
      end

      def jira_integration_configured?
        return if @project.jira_service

        flash[:notice] = _("Configure the Jira integration first on your project's %{strong_start} Settings > Integrations > Jira%{strong_end} page." %
           { strong_start: '<strong>'.html_safe, strong_end: '</strong>'.html_safe })
        redirect_to project_issues_path(@project)
      end

      def jira_import_params
        params.permit(:jira_project_key)
      end
    end
  end
end
