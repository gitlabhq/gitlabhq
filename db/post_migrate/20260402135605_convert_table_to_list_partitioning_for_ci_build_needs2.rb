# frozen_string_literal: true

class ConvertTableToListPartitioningForCiBuildNeeds2 < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '18.11'
  disable_ddl_transaction!

  TABLE_NAME = :ci_build_needs
  PARENT_TABLE_NAME = :p_ci_build_needs
  FIRST_PARTITION = (100..111).to_a
  PARTITION_COLUMN = :partition_id

  def up
    convert_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end

  def down
    revert_converting_table_to_first_list_partition(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
