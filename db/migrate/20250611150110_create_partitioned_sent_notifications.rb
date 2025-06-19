# frozen_string_literal: true

class CreatePartitionedSentNotifications < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.2'

  def up
    partition_table_by_date 'sent_notifications', :created_at, min_date: Date.new(2025, 4)
  end

  def down
    drop_partitioned_table_for 'sent_notifications'
  end
end
