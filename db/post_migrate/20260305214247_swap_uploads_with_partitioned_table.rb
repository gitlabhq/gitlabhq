# frozen_string_literal: true

class SwapUploadsWithPartitionedTable < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.11'

  disable_ddl_transaction!

  TABLE_NAME = 'uploads'

  def up
    replace_with_partitioned_table(TABLE_NAME, rename_partitions: false)
  end

  def down
    rollback_replace_with_partitioned_table(TABLE_NAME, rename_partitions: false)
  end
end
