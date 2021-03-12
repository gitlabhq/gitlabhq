# frozen_string_literal: true

class BackfillPartitionedWebHookLogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    enqueue_partitioning_data_migration :web_hook_logs
  end

  def down
    cleanup_partitioning_data_migration :web_hook_logs
  end
end
