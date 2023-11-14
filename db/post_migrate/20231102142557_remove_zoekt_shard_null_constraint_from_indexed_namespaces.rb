# frozen_string_literal: true

class RemoveZoektShardNullConstraintFromIndexedNamespaces < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  def up
    change_column_null :zoekt_indexed_namespaces, :zoekt_shard_id, true
  end

  def down
    change_column_null :zoekt_indexed_namespaces, :zoekt_shard_id, false
  end
end
