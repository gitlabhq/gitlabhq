# frozen_string_literal: true

class AddWorkflowForeignKeyToDuoWorkflowsSessionFiles < Gitlab::Database::Migration[2.4]
  milestone '19.6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :duo_workflows_session_files, :duo_workflows_workflows,
      column: :workflow_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_workflows_session_files, column: :workflow_id
    end
  end
end
