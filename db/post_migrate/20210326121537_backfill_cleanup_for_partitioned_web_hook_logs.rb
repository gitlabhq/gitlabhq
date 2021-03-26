# frozen_string_literal: true

class BackfillCleanupForPartitionedWebHookLogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    finalize_backfilling_partitioned_table :web_hook_logs
  end

  def down
    # no op
  end
end
