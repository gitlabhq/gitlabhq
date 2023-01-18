# frozen_string_literal: true

class AddRunnerMachinesContactedAtIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runner_machines_on_contacted_at_desc_and_id_desc'

  def up
    add_concurrent_index :ci_runner_machines, [:contacted_at, :id], order: { contacted_at: :desc, id: :desc },
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runner_machines, INDEX_NAME
  end
end
