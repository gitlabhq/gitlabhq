# frozen_string_literal: true

class MigrateGlobalSearchSettingsInApplicationSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    ApplicationSetting.reset_column_information

    application_setting = ApplicationSetting.last
    return unless application_setting

    # rubocop:disable Gitlab/FeatureFlagWithoutActor -- Does not execute in user context
    search = {
      global_search_issues_enabled: Feature.enabled?(:global_search_issues_tab, type: :ops),
      global_search_merge_requests_enabled: Feature.enabled?(:global_search_merge_requests_tab, type: :ops),
      global_search_snippet_titles_enabled: Feature.enabled?(:global_search_snippet_titles_tab, type: :ops),
      global_search_users_enabled: Feature.enabled?(:global_search_users_tab, type: :ops)
    }

    if Gitlab.ee?
      search.merge!(
        global_search_code_enabled: Feature.enabled?(:global_search_code_tab, type: :ops),
        global_search_commits_enabled: Feature.enabled?(:global_search_commits_tab, type: :ops),
        global_search_epics_enabled: Feature.enabled?(:global_search_epics_tab, type: :ops),
        global_search_wiki_enabled: Feature.enabled?(:global_search_wiki_tab, type: :ops)
      )
    end
    # rubocop:enable Gitlab/FeatureFlagWithoutActor

    application_setting.update_columns(search: search, updated_at: Time.current)
  end

  def down
    application_setting = ApplicationSetting.last
    return unless application_setting

    application_setting.update_column(:search, {})
  end
end
