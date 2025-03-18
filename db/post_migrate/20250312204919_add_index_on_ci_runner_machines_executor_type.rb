# frozen_string_literal: true

class AddIndexOnCiRunnerMachinesExecutorType < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.10'

  TABLE = :ci_runner_machines
  COLUMN = :executor_type
  INDEX_NAME = :index_ci_runner_machines_on_executor_type

  def up
    add_concurrent_partitioned_index(TABLE, COLUMN, name: INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE, INDEX_NAME)
  end
end
