# frozen_string_literal: true

class AddUniqueNamespacesIndexOnNameParentIdAndType < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_namespaces_name_parent_id_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :namespaces, [:name, :parent_id, :type], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end
end
