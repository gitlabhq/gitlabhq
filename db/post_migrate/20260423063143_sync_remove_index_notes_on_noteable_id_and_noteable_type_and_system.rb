# frozen_string_literal: true

class SyncRemoveIndexNotesOnNoteableIdAndNoteableTypeAndSystem < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  INDEX_NAME = 'index_notes_on_noteable_id_and_noteable_type_and_system'

  def up
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end

  def down
    add_concurrent_index :notes, [:noteable_id, :noteable_type, :system], name: INDEX_NAME
  end
end
