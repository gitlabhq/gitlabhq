# frozen_string_literal: true

class BackfillCleanupForPartitionedAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    finalize_backfilling_partitioned_table :audit_events
  end

  def down
    # no op
  end
end
