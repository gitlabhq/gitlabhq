# frozen_string_literal: true

class AddContainerRegistrySizeToNamespaceRootStorageStatistics < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :namespace_root_storage_statistics, :container_registry_size, :bigint, default: 0, null: false
  end
end
