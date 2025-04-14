# frozen_string_literal: true

class AddAllowAgentToRequestUserToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :duo_workflows_workflows, :allow_agent_to_request_user, :boolean, default: true, null: false
  end
end
