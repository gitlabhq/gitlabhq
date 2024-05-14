# frozen_string_literal: true

class AddWorkspaceVariablesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :workspace_variables, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :workspace_variables, column: :project_id
    end
  end
end
