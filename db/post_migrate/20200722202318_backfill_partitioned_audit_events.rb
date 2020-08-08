# frozen_string_literal: true

class BackfillPartitionedAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return if ::Gitlab.com?

    enqueue_partitioning_data_migration :audit_events
  end

  def down
    return if ::Gitlab.com?

    cleanup_partitioning_data_migration :audit_events
  end
end
