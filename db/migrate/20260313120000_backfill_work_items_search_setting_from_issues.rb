# frozen_string_literal: true

class BackfillWorkItemsSearchSettingFromIssues < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.11'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return unless application_setting

    search_settings = application_setting.search&.dup || {}

    # Copy the value from global_search_issues_enabled to global_search_work_items_enabled
    # Default to true if the issues setting doesn't exist
    issues_enabled = search_settings.fetch('global_search_issues_enabled', true)
    search_settings['global_search_work_items_enabled'] = issues_enabled

    application_setting.update_columns(search: search_settings, updated_at: Time.current)
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    search_settings = application_setting.search
    search_settings.delete('global_search_work_items_enabled')
    application_setting.update_columns(search: search_settings, updated_at: Time.current)
  end
end
