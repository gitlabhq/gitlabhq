# frozen_string_literal: true

class RemoveGlobalSearchIssuesAndEpicsSettings < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '19.0'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return unless application_setting

    search_settings = application_setting.search&.dup || {}

    search_settings.delete('global_search_issues_enabled')
    search_settings.delete('global_search_epics_enabled')

    application_setting.update_columns(search: search_settings, updated_at: Time.current)
  end

  def down
    # This migration is irreversible because we cannot restore the original values of the deleted keys.
  end
end
