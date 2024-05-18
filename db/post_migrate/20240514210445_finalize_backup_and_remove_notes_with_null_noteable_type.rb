# frozen_string_literal: true

class FinalizeBackupAndRemoveNotesWithNullNoteableType < Gitlab::Database::Migration[2.2]
  MIGRATION = 'BackupAndRemoveNotesWithNullNoteableType'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell
  milestone '17.1'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :notes,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
