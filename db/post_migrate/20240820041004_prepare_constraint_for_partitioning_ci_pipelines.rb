# frozen_string_literal: true

class PrepareConstraintForPartitioningCiPipelines < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  disable_ddl_transaction!
  milestone '17.4'

  TABLE_NAME = :ci_pipelines
  PARENT_TABLE_NAME = :p_ci_pipelines
  FIRST_PARTITION = (100..102).to_a
  PARTITION_COLUMN = :partition_id

  def up
    prepare_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION,
      async: true
    )
  end

  def down
    revert_preparing_constraint_for_list_partitioning(
      table_name: TABLE_NAME,
      partitioning_column: PARTITION_COLUMN,
      parent_table_name: PARENT_TABLE_NAME,
      initial_partitioning_value: FIRST_PARTITION
    )
  end
end
