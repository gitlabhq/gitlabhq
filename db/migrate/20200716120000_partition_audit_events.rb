# frozen_string_literal: true

class PartitionAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::PartitioningMigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    partition_table_by_date :audit_events, :created_at
  end

  def down
    drop_partitioned_table_for :audit_events
  end
end
