# frozen_string_literal: true

class QueueBackupAndRemoveNotesWithNullNoteableType < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackupAndRemoveNotesWithNullNoteableType"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 50

  def up
    queue_batched_background_migration(
      MIGRATION,
      :notes,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      gitlab_schema: :gitlab_main_cell
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :notes, :id, [])
  end
end
