# frozen_string_literal: true

class CleanupAttentionRequestRelatedSystemNotes < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 100

  class SystemNoteMetadata < MigrationRecord
    include EachBatch

    self.table_name = 'system_note_metadata'
  end

  class Note < MigrationRecord
    self.table_name = 'notes'
  end

  def up
    SystemNoteMetadata
      .where(action: %w[attention_requested attention_request_removed])
      .each_batch(of: BATCH_SIZE) do |batch|
        Note.where(id: batch.pluck(:note_id)).delete_all
      end
  end

  def down
    # no op
  end
end
