# frozen_string_literal: true

class CreateZoektReplicasFkIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  ZKT_NAMESPACE_INDEX_NAME = 'index_zoekt_replicas_on_enabled_namespace_id'

  def up
    add_concurrent_index :zoekt_replicas, :zoekt_enabled_namespace_id, name: ZKT_NAMESPACE_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_replicas, ZKT_NAMESPACE_INDEX_NAME
  end
end
