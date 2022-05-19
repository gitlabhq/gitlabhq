# frozen_string_literal: true

class BackfillNullNoteDiscussionIds < Gitlab::Database::Migration[2.0]
  MIGRATION = 'BackfillNoteDiscussionId'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  class Note < MigrationRecord
    include EachBatch

    self.table_name = 'notes'
    self.inheritance_column = :_type_disabled
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Note.where(discussion_id: nil),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
