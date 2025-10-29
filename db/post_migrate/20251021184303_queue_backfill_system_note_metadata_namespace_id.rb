# frozen_string_literal: true

class QueueBackfillSystemNoteMetadataNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillSystemNoteMetadataNamespaceId"
  BATCH_SIZE = 30_000
  SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :system_note_metadata,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :system_note_metadata, :id, [])
  end
end
