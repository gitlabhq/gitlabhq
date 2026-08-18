# frozen_string_literal: true

class AddTriggerMetadataToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      ADD COLUMN IF NOT EXISTS trigger_source Int16 DEFAULT 0,
      ADD COLUMN IF NOT EXISTS trigger_flow_trigger_id Nullable(Int64);
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      DROP COLUMN IF EXISTS trigger_source,
      DROP COLUMN IF EXISTS trigger_flow_trigger_id;
    SQL
  end
end
