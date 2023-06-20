# frozen_string_literal: true

class QueueBackfillResourceLinkEvents < Gitlab::Database::Migration[2.1]
  MIGRATION = "BackfillResourceLinkEvents"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 10

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class SystemNoteMetadata < MigrationRecord
    self.table_name = 'system_note_metadata'

    def self.batch_start_id
      SystemNoteMetadata
        .select(:id)
        .where("action='relate_to_parent' OR action='unrelate_from_parent'")
        .order(id: :asc)
        .limit(1)
        .first&.id
    end
  end

  def up
    batch_min_value = SystemNoteMetadata.batch_start_id

    return unless batch_min_value

    queue_batched_background_migration(
      MIGRATION,
      :system_note_metadata,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_min_value: batch_min_value
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :system_note_metadata, :id, [])
  end
end
