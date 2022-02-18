# frozen_string_literal: true

class BackfillNamespaceIdForNamespaceRoutes < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillNamespaceIdForNamespaceRoute'
  INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      :routes,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(MIGRATION, :routes, :id, [])
      .delete_all
  end
end
