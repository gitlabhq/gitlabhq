# frozen_string_literal: true

class IndexPCiRunnerMachineBuildsOnProjectId < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '17.4'

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_runner_machine_builds
  PARTITIONED_INDEX_NAME = :index_p_ci_runner_machine_builds_on_project_id

  def up
    add_concurrent_partitioned_index(TABLE_NAME, :project_id, name: PARTITIONED_INDEX_NAME)
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, PARTITIONED_INDEX_NAME)
  end
end
