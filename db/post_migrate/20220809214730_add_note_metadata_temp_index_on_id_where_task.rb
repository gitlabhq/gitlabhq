# frozen_string_literal: true

class AddNoteMetadataTempIndexOnIdWhereTask < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'tmp_index_system_note_metadata_on_id_where_task'

  disable_ddl_transaction!

  def up
    add_concurrent_index :system_note_metadata, [:id, :action], where: "action = 'task'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end
end
