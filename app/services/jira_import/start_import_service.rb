# frozen_string_literal: true

module JiraImport
  class StartImportService
    attr_reader :user, :project, :jira_project_key

    def initialize(user, project, jira_project_key)
      @user = user
      @project = project
      @jira_project_key = jira_project_key
    end

    def execute
      validation_response = validate
      return validation_response if validation_response&.error?

      create_and_schedule_import
    end

    private

    def create_and_schedule_import
      jira_import = build_jira_import
      project.import_type = 'jira'
      project.save! && jira_import.schedule!

      ServiceResponse.success(payload: { import_data: jira_import } )
    rescue => ex
      # in case project.save! raises an erorr
      Gitlab::ErrorTracking.track_exception(ex, project_id: project.id)
      build_error_response(ex.message)
      jira_import.do_fail!
    end

    def build_jira_import
      project.jira_imports.build(
        user: user,
        jira_project_key: jira_project_key,
        # we do not have the jira_project_name or jira_project_xid yet so just set a mock value,
        # we will once https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28190
        jira_project_name: jira_project_key,
        jira_project_xid: 0
      )
    end

    def validate
      return build_error_response(_('Jira import feature is disabled.')) unless project.jira_issues_import_feature_flag_enabled?
      return build_error_response(_('You do not have permissions to run the import.')) unless user.can?(:admin_project, project)
      return build_error_response(_('Cannot import because issues are not available in this project.')) unless project.feature_available?(:issues, user)
      return build_error_response(_('Jira integration not configured.')) unless project.jira_service&.active?
      return build_error_response(_('Unable to find Jira project to import data from.')) if jira_project_key.blank?
      return build_error_response(_('Jira import is already running.')) if import_in_progress?
    end

    def build_error_response(message)
      ServiceResponse.error(message: message, http_status: 400)
    end

    def import_in_progress?
      project.latest_jira_import&.in_progress?
    end
  end
end
