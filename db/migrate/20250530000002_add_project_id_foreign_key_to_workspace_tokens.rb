# frozen_string_literal: true

class AddProjectIdForeignKeyToWorkspaceTokens < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    add_concurrent_foreign_key :workspace_tokens, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :workspace_tokens, column: :project_id
    end
  end
end
