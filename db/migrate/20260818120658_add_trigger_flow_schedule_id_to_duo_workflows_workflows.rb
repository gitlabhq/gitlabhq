# frozen_string_literal: true

class AddTriggerFlowScheduleIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :duo_workflows_workflows, :trigger_flow_schedule_id, :bigint
  end
end
