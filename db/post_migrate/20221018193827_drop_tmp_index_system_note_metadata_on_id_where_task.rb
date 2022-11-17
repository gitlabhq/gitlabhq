# frozen_string_literal: true

class DropTmpIndexSystemNoteMetadataOnIdWhereTask < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_system_note_metadata_on_id_where_task'

  def up
    remove_concurrent_index_by_name :system_note_metadata, INDEX_NAME
  end

  def down
    add_concurrent_index :system_note_metadata, [:id, :action], where: "action = 'task'", name: INDEX_NAME
  end
end
