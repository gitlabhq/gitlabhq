# frozen_string_literal: true

class AddNotNullConstraintToPCiBuilds < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  CONSTRAINT_NAME = 'check_9aa9432137'

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      add_not_null_constraint partition.identifier, :project_id, constraint_name: CONSTRAINT_NAME, validate: false
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      remove_not_null_constraint partition.identifier, :project_id, constraint_name: CONSTRAINT_NAME
    end
  end
end
