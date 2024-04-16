# frozen_string_literal: true

class MigrateZoektSettingsInApplicationSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.11'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    return unless Gitlab.ee? # zoekt_settings available only in EE version

    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return if application_setting.nil? || application_setting.zoekt_settings.any?

    zoekt_settings = {
      zoekt_indexing_enabled: Feature.enabled?(:index_code_with_zoekt),
      zoekt_indexing_paused: Feature.enabled?(:zoekt_pause_indexing, type: :ops),
      zoekt_search_enabled: Feature.enabled?(:search_code_with_zoekt)
    }
    application_setting.update!(zoekt_settings: zoekt_settings)
  end

  def down
    # No op
  end
end
