class RemoveCommasFromWeightNote < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:system_note_metadata, :action, where: "action = 'weight'")

    notes_table = Arel::Table.new(:notes)
    metadata_table = Arel::Table.new(:system_note_metadata)
    update_value = Arel.sql("TRIM(TRAILING ',' FROM note), note_html = NULL")

    weight_system_notes =
      notes_table
        .join(metadata_table).on(notes_table[:id].eq(metadata_table[:note_id]))
        .where(metadata_table[:action].eq('weight'))
        .where(notes_table[:system].eq(true))
        .where(notes_table[:note].matches('%,'))
        .project(notes_table[:id])

    if Gitlab::Database.mysql?
      weight_system_notes = weight_system_notes.from(
        notes_table.project([notes_table[:id], notes_table[:system]]).as('notes')
      )
    end

    update_column_in_batches(:notes, :note, update_value) do |table, query|
      query.where(table[:id].in(weight_system_notes))
    end

    remove_concurrent_index(:system_note_metadata, :action)
  end

  def down
    # We can't reliably find notes that would need a comma, so do nothing
  end
end
