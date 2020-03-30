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
      import_data = project.create_or_update_import_data(data: {}).becomes(JiraImportData)
      jira_project_details = JiraImportData::JiraProjectDetails.new(
        jira_project_key,
        Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        { user_id: user.id, name: user.name }
      )
      import_data << jira_project_details
      import_data.force_import!

      project.import_type = 'jira'
      project.import_state.schedule if project.save!

      ServiceResponse.success(payload: { import_data: import_data } )
    rescue => ex
      # in case project.save! raises an erorr
      Gitlab::ErrorTracking.track_exception(ex, project_id: project.id)
      build_error_response(ex.message)
    end

    def validate
      return build_error_response(_('Jira import feature is disabled.')) unless Feature.enabled?(:jira_issue_import, project)
      return build_error_response(_('You do not have permissions to run the import.')) unless user.can?(:admin_project, project)
      return build_error_response(_('Jira integration not configured.')) unless project.jira_service&.active?
      return build_error_response(_('Unable to find Jira project to import data from.')) if jira_project_key.blank?
      return build_error_response(_('Jira import is already running.')) if import_in_progress?
    end

    def build_error_response(message)
      import_data = JiraImportData.new(project: project)
      import_data.errors.add(:base, message)
      ServiceResponse.error(
        message: import_data.errors.full_messages.to_sentence,
        http_status: 400,
        payload: { import_data: import_data }
      )
    end

    def import_in_progress?
      import_state = project.import_state || project.create_import_state
      import_state.in_progress?
    end
  end
end
