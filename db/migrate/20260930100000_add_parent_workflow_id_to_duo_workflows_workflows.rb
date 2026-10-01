# frozen_string_literal: true

class AddParentWorkflowIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :duo_workflows_workflows, :parent_workflow_id, :bigint, null: true
  end
end
