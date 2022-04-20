# frozen_string_literal: true

class AddNotificationLevelToNamespaceRootStorageStatistics < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :namespace_root_storage_statistics, :notification_level, :integer, limit: 2, default: 100, null: false
  end

  def down
    remove_column :namespace_root_storage_statistics, :notification_level
  end
end
