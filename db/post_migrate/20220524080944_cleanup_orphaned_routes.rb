# frozen_string_literal: true

class CleanupOrphanedRoutes < Gitlab::Database::Migration[2.0]
  MIGRATION = 'CleanupOrphanedRoutes'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 100_000
  MAX_BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :routes,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      gitlab_schema: :gitlab_main
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :routes, :id, [])
  end
end
