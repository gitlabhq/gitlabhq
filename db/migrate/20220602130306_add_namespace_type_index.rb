# frozen_string_literal: true

class AddNamespaceTypeIndex < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_groups_on_parent_id_id'

  def up
    add_concurrent_index :namespaces, [:parent_id, :id], where: "type = 'Group'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:namespaces, INDEX_NAME)
  end
end
