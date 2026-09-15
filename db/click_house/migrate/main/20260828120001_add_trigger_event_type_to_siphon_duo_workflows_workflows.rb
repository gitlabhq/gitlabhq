# frozen_string_literal: true

class AddTriggerEventTypeToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      ADD COLUMN IF NOT EXISTS trigger_event_type Nullable(Int16);
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      DROP COLUMN IF EXISTS trigger_event_type;
    SQL
  end
end
