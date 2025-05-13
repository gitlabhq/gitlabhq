# frozen_string_literal: true

class MigrateGlobalSearchSettingsInApplicationSettingsV2 < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    # no-op
    # references to feature flags removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188747
  end

  def down
    # No op
  end
end
