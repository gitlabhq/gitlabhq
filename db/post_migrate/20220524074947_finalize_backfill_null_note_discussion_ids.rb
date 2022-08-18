# frozen_string_literal: true

class FinalizeBackfillNullNoteDiscussionIds < Gitlab::Database::Migration[2.0]
  MIGRATION = 'BackfillNoteDiscussionId'
  BATCH_SIZE = 10_000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION)

    define_batchable_model('notes').where(discussion_id: nil).each_batch(of: BATCH_SIZE) do |batch|
      range = batch.pick('MIN(id)', 'MAX(id)')

      Gitlab::BackgroundMigration::BackfillNoteDiscussionId.new.perform(*range)
    end
  end

  def down
  end
end
