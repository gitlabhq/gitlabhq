class CleanUpFromWeightSystemNoteCommaMigration < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'RemoveCommaFromWeightSystemNotes'.freeze
  BATCH_SIZE = 1000

  class Note < ActiveRecord::Base
    self.table_name = 'notes'

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION)

    migrate_inline if weight_system_notes.any?
  end

  def down
  end

  private

  def weight_system_notes
    Note
      .joins('INNER JOIN system_note_metadata ON notes.id = system_note_metadata.note_id')
      .where(system: true)
      .where(system_note_metadata: { action: 'weight' })
      .where("notes.note LIKE '%,'")
  end

  def migrate_inline
    add_concurrent_index(:system_note_metadata, :action, where: "action = 'weight'")

    weight_system_notes.each_batch(of: BATCH_SIZE) do |relation, index|
      ids = relation.pluck(:id)

      Gitlab::BackgroundMigration::RemoveCommaFromWeightSystemNotes.new.perform(ids)
    end

    remove_concurrent_index(:system_note_metadata, :action, where: "action = 'weight'")
  end
end
