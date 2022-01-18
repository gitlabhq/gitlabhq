# frozen_string_literal: true

class RemoveNoteIdIndex < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  TABLE = :suggestions
  INDEX_NAME = 'index_suggestions_on_note_id'

  def up
    remove_concurrent_index_by_name TABLE, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE, :note_id, name: INDEX_NAME
  end
end
