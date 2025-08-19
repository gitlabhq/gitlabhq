# frozen_string_literal: true

class DropPartitionedByCreatedAtSentNotificationsTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.3'
  disable_ddl_transaction!

  def up
    drop_partitioned_table_for 'sent_notifications'
  end

  def down
    partition_table_by_date 'sent_notifications', :created_at, min_date: Date.new(2025, 4)
  end
end
