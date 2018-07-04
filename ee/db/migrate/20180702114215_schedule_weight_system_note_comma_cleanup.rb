class ScheduleWeightSystemNoteCommaCleanup < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'RemoveCommaFromWeightSystemNotes'.freeze
  BATCH_SIZE = 1000
  DELAY_INTERVAL = 5.minutes.to_i

  class Note < ActiveRecord::Base
    self.table_name = 'notes'

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    add_concurrent_index(:system_note_metadata, :action, where: "action = 'weight'")

    weight_system_notes =
      Note
        .joins('INNER JOIN system_note_metadata ON notes.id = system_note_metadata.note_id')
        .where(system: true)
        .where(system_note_metadata: { action: 'weight' })
        .where("notes.note LIKE '%,'")

    weight_system_notes.each_batch(of: BATCH_SIZE) do |relation, index|
      ids = relation.pluck(:id)
      delay = index * DELAY_INTERVAL

      BackgroundMigrationWorker.perform_in(delay, MIGRATION, [ids])
    end

    remove_concurrent_index(:system_note_metadata, :action, where: "action = 'weight'")
  end

  def down
  end
end
