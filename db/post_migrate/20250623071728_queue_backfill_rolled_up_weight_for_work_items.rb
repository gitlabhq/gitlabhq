# frozen_string_literal: true

class QueueBackfillRolledUpWeightForWorkItems < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillRolledUpWeightForWorkItems"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50000
  SUB_BATCH_SIZE = 2500

  def up
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
