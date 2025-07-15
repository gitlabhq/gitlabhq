# frozen_string_literal: true

class AddNamespaceIdToDuoWorkflowsCheckpointWrites < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :duo_workflows_checkpoint_writes, :namespace_id, :bigint
  end
end
