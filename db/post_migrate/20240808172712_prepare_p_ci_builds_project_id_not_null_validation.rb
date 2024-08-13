# frozen_string_literal: true

class PreparePCiBuildsProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  CONSTRAINT_NAME = 'check_9aa9432137'

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      prepare_async_check_constraint_validation partition.identifier, name: CONSTRAINT_NAME
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      unprepare_async_check_constraint_validation partition.identifier, name: CONSTRAINT_NAME
    end
  end
end
