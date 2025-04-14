# frozen_string_literal: true

class MigrateGlobalSearchSettingsInApplicationSettingsV2 < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return unless application_setting

    # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Does not execute in user context
    search_settings = application_setting.search
    search_settings[:global_search_block_anonymous_searches_enabled] =
      Feature.enabled?(:block_anonymous_global_searches)

    if Gitlab.ee?
      search_settings[:global_search_limited_indexing_enabled] =
        Feature.enabled?(:advanced_global_search_for_limited_indexing)
    end
    # rubocop:enable Gitlab/FeatureFlagWithoutActor

    application_setting.update_columns(search: search_settings, updated_at: Time.current)
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    search_settings_hash = application_setting.search
    search_settings_hash.delete('global_search_block_anonymous_searches_enabled')
    search_settings_hash.delete('global_search_limited_indexing_enabled')
    application_setting.update_column(:search, search_settings_hash)
  end
end
