# frozen_string_literal: true

class CreatePCiJobRuntimeEnvironments < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.3'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_job_runtime_environments

  RUNTIME_ENVIRONMENT_INDEX_NAME = :idx_p_ci_job_runtime_envs_on_runtime_environment_id
  RUNNER_MACHINE_INDEX_NAME = :idx_p_ci_job_runtime_envs_on_runner_machine_id
  PROJECT_INDEX_NAME = :idx_p_ci_job_runtime_envs_on_project_id

  def up
    creation_options = {
      primary_key: [:build_id, :partition_id],
      options: 'PARTITION BY LIST (partition_id)',
      if_not_exists: true
    }

    create_table TABLE_NAME, **creation_options do |t|
      t.bigint :build_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :runtime_environment_id
      t.bigint :runner_machine_id
      t.bigint :project_id, null: false
      t.boolean :suspend_on_success, null: false, default: false
      t.boolean :suspend_on_failure, null: false, default: false
    end

    add_concurrent_partitioned_index TABLE_NAME, [:runtime_environment_id, :build_id, :runner_machine_id],
      name: RUNTIME_ENVIRONMENT_INDEX_NAME
    add_concurrent_partitioned_index TABLE_NAME, :runner_machine_id, name: RUNNER_MACHINE_INDEX_NAME
    add_concurrent_partitioned_index TABLE_NAME, :project_id, name: PROJECT_INDEX_NAME
  end

  def down
    drop_table TABLE_NAME, if_exists: true
  end
end
