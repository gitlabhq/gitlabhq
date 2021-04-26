# frozen_string_literal: true

class SwapPartitionedWebHookLogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  def up
    replace_with_partitioned_table :web_hook_logs
  end

  def down
    rollback_replace_with_partitioned_table :web_hook_logs
  end
end
