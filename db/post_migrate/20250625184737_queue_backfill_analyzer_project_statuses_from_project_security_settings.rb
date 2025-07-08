# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on when/how to queue batched background migrations

# Update below commented lines with appropriate values.

class QueueBackfillAnalyzerProjectStatusesFromProjectSecuritySettings < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  # Select the applicable gitlab schema for your batched background migration
  # the project_security_settings are on gitlab_main
  # but analyzer_project_statuses is on gitlab_sec
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillAnalyzerProjectStatusesFromProjectSecuritySettings"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :project_security_settings,
      :project_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :project_security_settings, :project_id, [])
  end
end
