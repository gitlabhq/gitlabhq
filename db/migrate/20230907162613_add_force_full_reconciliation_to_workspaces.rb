# frozen_string_literal: true

class AddForceFullReconciliationToWorkspaces < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :workspaces, :force_full_reconciliation, :boolean, default: false, null: false
  end
end
