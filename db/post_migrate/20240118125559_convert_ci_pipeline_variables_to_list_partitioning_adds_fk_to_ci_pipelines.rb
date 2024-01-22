# frozen_string_literal: true

class ConvertCiPipelineVariablesToListPartitioningAddsFkToCiPipelines < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  disable_ddl_transaction!

  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  TABLE_NAME = :ci_pipeline_variables
  PARENT_TABLE_NAME = :p_ci_pipeline_variables
  FIRST_PARTITION = [100, 101]
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
