# frozen_string_literal: true

class QueueBackfillSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillSbomOccurrenceRefs"
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 1000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sbom_occurrences,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sbom_occurrences, :id, [])
  end
end
