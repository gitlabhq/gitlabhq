# frozen_string_literal: true

# This index was prepared in 17.9 PrepareNoteableIdNoteableTypeAndIdIndexInNotesTable migration
class AddNoteableIdNoteableTypeAndIdIndexInNotesTable < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_notes_on_noteable_id_noteable_type_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- index prepared in advance
    add_concurrent_index :notes, [:noteable_id, :noteable_type, :id], name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
