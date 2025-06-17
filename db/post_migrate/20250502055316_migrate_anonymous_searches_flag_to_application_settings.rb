# frozen_string_literal: true

class MigrateAnonymousSearchesFlagToApplicationSettings < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.0'

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  # Marking this as a noop because the backfill migration incorrectly ignores the
  # default_enabled configuration value, causing wrong feature flag value to be added in setting.
  # Revert MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190832
  def up; end

  def down; end
end
