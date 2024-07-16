# frozen_string_literal: true

class AddNamespaceIndexToZoektReplicas < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'
  INDEX_NAME = 'index_zoekt_replicas_on_namespace_id_enabled_namespace_id'

  def up
    add_concurrent_index :zoekt_replicas, [:namespace_id, :zoekt_enabled_namespace_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_replicas, INDEX_NAME
  end
end
