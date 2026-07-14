# frozen_string_literal: true

class AddIncrementalCheckpointsEnabledToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN IF NOT EXISTS incremental_checkpoints_enabled Nullable(Bool);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN IF EXISTS incremental_checkpoints_enabled;
    SQL
  end
end
