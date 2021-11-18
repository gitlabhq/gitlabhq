# frozen_string_literal: true

class AddIndexToTmpProjectIdColumnOnNamespacesTable < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_on_tmp_project_id_on_namespaces'

  def up
    add_concurrent_index :namespaces, :tmp_project_id, name: INDEX_NAME, unique: true
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end
