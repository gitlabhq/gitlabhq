# frozen_string_literal: true

class QueueBackfillWorkItemPositionsRelativePositioningNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillWorkItemPositionsRelativePositioningNamespaceId"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :work_item_positions,
      :work_item_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :work_item_positions, :work_item_id, [])
  end
end
