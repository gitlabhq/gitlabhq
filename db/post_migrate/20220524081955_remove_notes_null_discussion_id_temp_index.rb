# frozen_string_literal: true

class RemoveNotesNullDiscussionIdTempIndex < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_notes_on_id_where_discussion_id_is_null'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :notes, INDEX_NAME
  end

  def down
    add_concurrent_index :notes, :id, where: 'discussion_id IS NULL', name: INDEX_NAME
  end
end
