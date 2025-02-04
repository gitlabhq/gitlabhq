# frozen_string_literal: true

class CreateDuoWorkflowCheckpointWriteProjectFkey < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :duo_workflows_checkpoint_writes,
      :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :duo_workflows_checkpoint_writes, column: :project_id
    end
  end
end
