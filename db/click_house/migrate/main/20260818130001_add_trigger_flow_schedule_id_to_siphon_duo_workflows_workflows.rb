# frozen_string_literal: true

class AddTriggerFlowScheduleIdToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      ADD COLUMN IF NOT EXISTS trigger_flow_schedule_id Nullable(Int64);
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      DROP COLUMN IF EXISTS trigger_flow_schedule_id;
    SQL
  end
end
