# frozen_string_literal: true

class ScheduleFixOrphanPromotedIssues < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 100
  BACKGROUND_MIGRATION = 'FixOrphanPromotedIssues'.freeze

  disable_ddl_transaction!

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'

    scope :of_promotion, -> do
      where(noteable_type: 'Issue')
        .where('notes.system IS TRUE')
        .where("notes.note LIKE 'promoted to epic%'")
    end
  end

  def up
    Note.of_promotion.each_batch(of: BATCH_SIZE) do |notes, index|
      jobs = notes.map { |note| [BACKGROUND_MIGRATION, [note.id]] }

      BackgroundMigrationWorker.bulk_perform_async(jobs)
    end
  end

  def down
    # NO OP
  end
end
