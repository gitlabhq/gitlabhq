# frozen_string_literal: true

class AddRunnerTypeToCiRunnerManagers < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX = 'index_ci_runner_machines_on_runner_type'

  def up
    with_lock_retries do
      add_column :ci_runner_machines, :runner_type, :smallint, null: true, if_not_exists: true
    end

    add_concurrent_index :ci_runner_machines, :runner_type, name: INDEX
  end

  def down
    remove_column :ci_runner_machines, :runner_type, if_exists: true
  end
end
