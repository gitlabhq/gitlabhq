# frozen_string_literal: true

class RenameRunnerMachineXid < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :ci_runner_machines, :machine_xid, :system_xid
  end

  def down
    undo_rename_column_concurrently :ci_runner_machines, :machine_xid, :system_xid
  end
end
