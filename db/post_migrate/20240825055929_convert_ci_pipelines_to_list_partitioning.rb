# frozen_string_literal: true

class ConvertCiPipelinesToListPartitioning < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.4'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipelines
  PARENT_TABLE_NAME = :p_ci_pipelines
  FIRST_PARTITION = (100..102).to_a
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
