# frozen_string_literal: true

class AddForkStorageSizeColumnsToRootStorageStatistics < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :namespace_root_storage_statistics, :public_forks_storage_size, :bigint, default: 0, null: false
    add_column :namespace_root_storage_statistics, :internal_forks_storage_size, :bigint, default: 0, null: false
    add_column :namespace_root_storage_statistics, :private_forks_storage_size, :bigint, default: 0, null: false
  end
end
