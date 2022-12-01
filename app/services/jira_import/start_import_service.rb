# frozen_string_literal: true

module JiraImport
  class StartImportService
    attr_reader :user, :project, :jira_project_key, :users_mapping

    def initialize(user, project, jira_project_key, users_mapping)
      @user = user
      @project = project
      @jira_project_key = jira_project_key
      @users_mapping = users_mapping
    end

    def execute
      validation_response = validate
      return validation_response if validation_response&.error?

      store_users_mapping
      create_and_schedule_import
    end

    private

    def store_users_mapping
      return if users_mapping.blank?

      mapping = users_mapping.map do |map|
        next if !map[:jira_account_id] || !map[:gitlab_id]

        [map[:jira_account_id], map[:gitlab_id]]
      end.compact.to_h

      return if mapping.blank?

      Gitlab::JiraImport.cache_users_mapping(project.id, mapping)
    end

    def create_and_schedule_import
      jira_import = build_jira_import
      project.import_type = 'jira'
      project.save! && jira_import.schedule!

      ServiceResponse.success(payload: { import_data: jira_import })
    rescue StandardError => ex
      # in case project.save! raises an error
      Gitlab::ErrorTracking.track_exception(ex, project_id: project.id)
      jira_import&.do_fail!(error_message: ex.message)
      build_error_response(ex.message)
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
      description = "Label for issues that were imported from Jira on #{import_start_time.strftime('%Y-%m-%d %H:%M:%S')}"
      color = ::Gitlab::Color.color_for(title).to_s
      { title: title, description: description, color: color }
    end

    def validate
      Gitlab::JiraImport.validate_project_settings!(project, user: user)

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
