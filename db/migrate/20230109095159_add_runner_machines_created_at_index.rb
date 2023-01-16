# frozen_string_literal: true

class AddRunnerMachinesCreatedAtIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runner_machines_on_created_at_and_id_desc'

  def up
    add_concurrent_index :ci_runner_machines, [:created_at, :id], order: { id: :desc }, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runner_machines, INDEX_NAME
  end
end
