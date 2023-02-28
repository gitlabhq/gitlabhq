# frozen_string_literal: true

class AddRegistrySizeEstimatedToNamespaceRootStorageStatistics < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_ns_root_stor_stats_on_registry_size_estimated'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_root_storage_statistics, :registry_size_estimated, :boolean, default: false, null: false
    end

    add_concurrent_index :namespace_root_storage_statistics, :registry_size_estimated, name: INDEX_NAME
  end

  def down
    with_lock_retries do
      remove_column :namespace_root_storage_statistics, :registry_size_estimated
    end
  end
end
