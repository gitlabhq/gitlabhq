# frozen_string_literal: true

class ScheduleDisableLegacyOpenSourceLicenseForNoIssuesNoRepoProjects < Gitlab::Database::Migration[2.0]
  MIGRATION = 'DisableLegacyOpenSourceLicenseForNoIssuesNoRepoProjects'
  INTERVAL = 2.minutes
  BATCH_SIZE = 5_000
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 200

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    return unless Gitlab.com?

    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless Gitlab.com?

    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
