# frozen_string_literal: true

class AddPCiJobAnnotationsProjectIdNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  TABLE_NAME = :p_ci_job_annotations
  COLUMN_NAME = :project_id
  CONSTRAINT_NAME = :check_375bb9900a

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      add_not_null_constraint(partition.identifier, COLUMN_NAME, constraint_name: CONSTRAINT_NAME, validate: false)
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      remove_not_null_constraint(partition.identifier, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
    end
  end
end
