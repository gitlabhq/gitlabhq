# frozen_string_literal: true

class AddWorkspaceIdWorkspaceAgentkStateForeignKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :workspace_agentk_states, :workspaces, column: :workspace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :workspace_agentk_states, column: :workspace_id
    end
  end
end
