# frozen_string_literal: true

class AddFkDuoWorkflowsWorkflowNotesToNotes < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_notes

  def up
    add_concurrent_foreign_key TABLE, :notes, column: :note_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE, column: :note_id
    end
  end
end
