# frozen_string_literal: true

class AddNamespaceIdToDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :duo_workflows_checkpoints, :namespace_id, :bigint
  end
end
