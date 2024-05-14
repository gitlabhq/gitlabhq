# frozen_string_literal: true

class DropIndexCiRunnerManagerBuildOnRunnerMachineId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.0'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_runner_machine_builds
  INDEX_NAME = :index_ci_runner_machine_builds_on_runner_machine_id

  def up
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_partitioned_index(TABLE_NAME, :runner_machine_id, name: INDEX_NAME)
  end
end
