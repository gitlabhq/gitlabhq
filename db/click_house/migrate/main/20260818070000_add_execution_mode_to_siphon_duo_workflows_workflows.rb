# frozen_string_literal: true

class AddExecutionModeToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      ADD COLUMN IF NOT EXISTS execution_mode Nullable(Int16);
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      DROP COLUMN IF EXISTS execution_mode;
    SQL
  end
end
