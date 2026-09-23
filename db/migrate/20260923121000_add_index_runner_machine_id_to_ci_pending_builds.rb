# frozen_string_literal: true

class AddIndexRunnerMachineIdToCiPendingBuilds < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_pending_builds_on_runner_machine_id'

  def up
    add_concurrent_index :ci_pending_builds, :runner_machine_id,
      where: 'runner_machine_id IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_pending_builds, INDEX_NAME
  end
end
