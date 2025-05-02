# frozen_string_literal: true

class DropWebHookLogsTableSyncTrigger < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.0'

  OLD_PARTITIONED_TABLE_NAME = 'web_hook_logs'
  NEW_PARTITIONED_TABLE_NAME = 'web_hook_logs_daily'

  def up
    drop_trigger_to_sync_tables(OLD_PARTITIONED_TABLE_NAME)
  end

  def down
    create_trigger_to_sync_tables(OLD_PARTITIONED_TABLE_NAME, NEW_PARTITIONED_TABLE_NAME, %w[id created_at])
  end
end
