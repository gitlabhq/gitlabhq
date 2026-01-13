# frozen_string_literal: true

class QueueBackfillDetectedAtToFindings < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillDetectedAtToFindings"
  SUB_BATCH_SIZE = 1000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :vulnerability_occurrences,
      :id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerability_occurrences, :id, [])
  end
end
