# frozen_string_literal: true

class QueueBackfillRolledUpWeightForWorkItemsV3 < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillRolledUpWeightForWorkItems"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50000
  SUB_BATCH_SIZE = 2500

  def up
    # Delete previous run to ensure we don't have 2 instances of this BBM running
    delete_batched_background_migration(MIGRATION, :issues, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
