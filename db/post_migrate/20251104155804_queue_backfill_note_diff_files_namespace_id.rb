# frozen_string_literal: true

class QueueBackfillNoteDiffFilesNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillNoteDiffFilesNamespaceId"
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :note_diff_files,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :note_diff_files, :id, [])
  end
end
