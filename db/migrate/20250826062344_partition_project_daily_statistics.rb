# frozen_string_literal: true

class PartitionProjectDailyStatistics < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.5'

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    partition_table_by_date 'project_daily_statistics', :date,
      min_date: Date.new(2025, 8, 1)
  end

  def down
    drop_partitioned_table_for 'project_daily_statistics'
  end
end
