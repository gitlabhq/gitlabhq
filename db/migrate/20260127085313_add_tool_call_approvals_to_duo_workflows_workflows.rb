# frozen_string_literal: true

class AddToolCallApprovalsToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :duo_workflows_workflows, :tool_call_approvals, :jsonb, default: {}, null: false
  end
end
