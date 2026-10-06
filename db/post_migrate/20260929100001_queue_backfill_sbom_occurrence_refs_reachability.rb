# frozen_string_literal: true

class QueueBackfillSbomOccurrenceRefsReachability < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillSbomOccurrenceRefsReachability"
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 1000

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sbom_occurrence_refs,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sbom_occurrence_refs, :id, [])
  end
end
