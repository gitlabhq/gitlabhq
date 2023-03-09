# frozen_string_literal: true

class AddIndexOnRunnerMachineIdOnRunnerMachineBuilds < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_p_ci_runner_machine_builds_on_runner_machine_id'

  def up
    add_concurrent_partitioned_index :p_ci_runner_machine_builds, :runner_machine_id, unique: false, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_ci_runner_machine_builds, INDEX_NAME
  end
end
