# frozen_string_literal: true

module Projects
  module Import
    class JiraController < Projects::ApplicationController
      before_action :authenticate_user!
      before_action :check_issues_available!
      before_action :authorize_read_project!
      before_action :jira_import_enabled?
      before_action :jira_integration_configured?
      before_action :authorize_admin_project!, only: [:import]

      def show
        @is_jira_configured = @project.jira_service.present?
        return if Feature.enabled?(:jira_issue_import_vue, @project)

        if !@project.latest_jira_import&.in_progress? && current_user&.can?(:admin_project, @project)
          jira_client = @project.jira_service.client
          jira_projects = jira_client.Project.all

          if jira_projects.present?
            @jira_projects = jira_projects.map { |p| ["#{p.name} (#{p.key})", p.key] }
          else
            flash[:alert] = 'No projects have been returned from Jira. Please check your Jira configuration.'
          end
        end

        flash[:notice] = _("Import %{status}") % { status: @project.jira_import_status } unless @project.latest_jira_import&.initial?
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
        return if @project.jira_issues_import_feature_flag_enabled?

        redirect_to project_issues_path(@project)
      end

      def jira_integration_configured?
        return if Feature.enabled?(:jira_issue_import_vue, @project)
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
