# frozen_string_literal: true

class AddNoteDuoMetadataWorkflowFk < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  def up
    add_concurrent_foreign_key :note_duo_metadata, :duo_workflows_workflows, column: :workflow_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :note_duo_metadata, column: :workflow_id
    end
  end
end
