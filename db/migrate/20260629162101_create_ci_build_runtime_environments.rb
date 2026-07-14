# frozen_string_literal: true

class CreateCiBuildRuntimeEnvironments < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    options = {
      if_not_exists: true,
      primary_key: [:build_id, :partition_id]
    }.freeze

    create_table(:ci_build_runtime_environments, **options) do |t|
      t.bigint :build_id, null: false
      t.bigint :partition_id, null: false
      t.bigint :runtime_environment_id
      t.bigint :runner_machine_id
      t.bigint :project_id, null: false
      t.boolean :suspend_on_success, null: false, default: false
      t.boolean :suspend_on_failure, null: false, default: false

      t.index :runtime_environment_id, name: 'index_ci_build_runtime_envs_on_runtime_environment_id'
      t.index :runner_machine_id, name: 'index_ci_build_runtime_envs_on_runner_machine_id'
      t.index :project_id, name: 'index_ci_build_runtime_envs_on_project_id'
    end
  end

  def down
    drop_table :ci_build_runtime_environments
  end
end
