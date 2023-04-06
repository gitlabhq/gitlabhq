# frozen_string_literal: true

class AddUniqueNamespaceIndexToStorageLimitExclusions < Gitlab::Database::Migration[2.1]
  TABLE_NAME = 'namespaces_storage_limit_exclusions'
  OLD_INDEX_NAME = 'index_namespaces_storage_limit_exclusions_on_namespace_id'
  NEW_INDEX_NAME = 'unique_idx_namespaces_storage_limit_exclusions_on_namespace_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index TABLE_NAME, :namespace_id,
      unique: true,
      name: NEW_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :namespace_id,
      unique: false,
      name: OLD_INDEX_NAME

    remove_concurrent_index_by_name TABLE_NAME, NEW_INDEX_NAME
  end
end
