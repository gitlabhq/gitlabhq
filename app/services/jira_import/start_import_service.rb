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
      label = create_import_label(project)
      project.jira_imports.build(
        user: user,
        label: label,
        jira_project_key: jira_project_key,
        # we do not have the jira_project_name or jira_project_xid yet so just set a mock value,
        # we will once https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28190
        jira_project_name: jira_project_key,
        jira_project_xid: 0
      )
    end

    def create_import_label(project)
      label = ::Labels::CreateService.new(build_label_attrs(project)).execute(project: project)
      raise Projects::ImportService::Error, _('Failed to create import label for jira import.') if label.blank?

      label
    end

    def build_label_attrs(project)
      import_start_time = Time.zone.now
      jira_imports_for_project = project.jira_imports.by_jira_project_key(jira_project_key).size + 1
      title = "jira-import::#{jira_project_key}-#{jira_imports_for_project}"
      description = "Label for issues that were imported from jira on #{import_start_time.strftime('%Y-%m-%d %H:%M:%S')}"
      color = "#{Label.color_for(title)}"
      { title: title, description: description, color: color }
    end

    def validate
      project.validate_jira_import_settings!(user: user)

      return build_error_response(_('Unable to find Jira project to import data from.')) if jira_project_key.blank?
      return build_error_response(_('Jira import is already running.')) if import_in_progress?
    rescue Projects::ImportService::Error => e
      build_error_response(e.message)
    end

    def build_error_response(message)
      ServiceResponse.error(message: message, http_status: 400)
    end

    def import_in_progress?
      project.latest_jira_import&.in_progress?
    end
  end
end
