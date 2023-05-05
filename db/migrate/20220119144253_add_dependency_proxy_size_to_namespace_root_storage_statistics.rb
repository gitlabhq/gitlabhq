# frozen_string_literal: true

class AddDependencyProxySizeToNamespaceRootStorageStatistics < Gitlab::Database::Migration[1.0]
  def change
    add_column :namespace_root_storage_statistics, :dependency_proxy_size, :bigint, default: 0, null: false
  end
end
