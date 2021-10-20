# frozen_string_literal: true

class DropUniqueNamespacesIndexOnNameAndParentId < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_namespaces_on_name_and_parent_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :namespaces, INDEX_NAME
  end

  def down
    add_concurrent_index :namespaces, [:name, :parent_id], unique: true, name: INDEX_NAME
  end
end
