# frozen_string_literal: true

class QueueCleanupStaleDeletionScheduledAt < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "CleanupStaleDeletionScheduledAt"

  BATCH_SIZE = 2_000
  MAX_BATCH_SIZE = 5_000
  SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespace_details,
      :namespace_id,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespace_details, :namespace_id, [])
  end
end
