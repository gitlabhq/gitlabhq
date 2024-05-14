# frozen_string_literal: true

class MigrateZoektSettingsInApplicationSettings < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.11'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    # no-op this was just a data migration which is already done in 16.11. The plan is to remove the feature-flags used
    # in this migration. So better to disable this migration in 17.0 to avoid any migration issues.
  end

  def down
    # No op
  end
end
