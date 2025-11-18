# frozen_string_literal: true

class DropTmpIndexNullProjectIdOnNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.6'

  def up
    remove_concurrent_index_by_name :notes, :tmp_index_null_project_id_on_notes
  end

  def down
    add_concurrent_index :notes, :id, name: :tmp_index_null_project_id_on_notes, where: 'project_id is NULL'
  end
end
