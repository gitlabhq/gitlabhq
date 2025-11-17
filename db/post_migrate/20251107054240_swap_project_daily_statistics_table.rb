# frozen_string_literal: true

class SwapProjectDailyStatisticsTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  milestone '18.6'

  def up
    replace_with_partitioned_table 'project_daily_statistics'
  end

  def down
    rollback_replace_with_partitioned_table 'project_daily_statistics'
  end
end
