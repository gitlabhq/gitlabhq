# frozen_string_literal: true

class AddTriggerMetadataToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :duo_workflows_workflows, :trigger_source, :integer, limit: 2, default: 0, null: false
    add_column :duo_workflows_workflows, :trigger_flow_trigger_id, :bigint
  end
end
