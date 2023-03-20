# frozen_string_literal: true

class ScheduleMigrationForRemediation < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'MigrateRemediationsForVulnerabilityFindings'
  DELAY_INTERVAL = 2.minutes
  SUB_BATCH_SIZE = 500
  BATCH_SIZE = 5000

  def up
    # no-op as described in https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
  end

  def down
    # no-op as described in https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
  end
end
