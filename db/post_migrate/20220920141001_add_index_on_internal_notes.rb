# frozen_string_literal: true

class AddIndexOnInternalNotes < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_notes_on_id_where_internal'

  disable_ddl_transaction!

  def up
    add_concurrent_index :notes, :id, where: 'internal = true', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end
end
