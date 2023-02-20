# frozen_string_literal: true

class CleanupCiRunnerMachinesMachineXidRename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :ci_runner_machines, :machine_xid, :system_xid
  end

  def down
    undo_cleanup_concurrent_column_rename :ci_runner_machines, :machine_xid, :system_xid
  end
end
