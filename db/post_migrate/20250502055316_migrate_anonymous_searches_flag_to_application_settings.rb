# frozen_string_literal: true

class MigrateAnonymousSearchesFlagToApplicationSettings < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.0'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return unless application_setting

    search_settings = application_setting.search
    search_settings[:anonymous_searches_allowed] = feature_flag_enabled?('allow_anonymous_searches')
    application_setting.update_columns(search: search_settings, updated_at: Time.current)
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    search_settings_hash = application_setting.search
    search_settings_hash.delete('anonymous_searches_allowed')
    application_setting.update_column(:search, search_settings_hash)
  end
end
