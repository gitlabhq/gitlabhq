# frozen_string_literal: true

class AddProjectIdNullConstraintToPCiPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_pipeline_variables
  COLUMN_NAME = :project_id
  CONSTRAINT_NAME = :check_6e932dbabf

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME, validate: false)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      add_not_null_constraint(partition.identifier, COLUMN_NAME, constraint_name: CONSTRAINT_NAME, validate: false)
    end
  end
end
