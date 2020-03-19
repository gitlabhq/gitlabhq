# frozen_string_literal: true

module Projects
  module Import
    class JiraController < Projects::ApplicationController
      before_action :jira_import_enabled?
      before_action :jira_integration_configured?

      def show
        unless @project.import_state&.in_progress?
          jira_client = @project.jira_service.client
          @jira_projects = jira_client.Project.all.map { |p| ["#{p.name} (#{p.key})", p.key] }
        end

        flash[:notice] = _("Import %{status}") % { status: @project.import_state.status } if @project.import_state.present? && !@project.import_state.none?
      end

      def import
        import_state = @project.import_state || @project.create_import_state

        schedule_import(jira_import_params) unless import_state.in_progress?

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

      def schedule_import(params)
        import_data = @project.create_or_update_import_data(data: {}).becomes(JiraImportData)

        import_data << JiraImportData::JiraProjectDetails.new(
          params[:jira_project_key],
          Time.now.strftime('%Y-%m-%d %H:%M:%S'),
          { user_id: current_user.id, name: current_user.name }
        )

        @project.import_type = 'jira'
        @project.import_state.schedule if @project.save
      end

      def jira_import_params
        params.permit(:jira_project_key)
      end
    end
  end
end
