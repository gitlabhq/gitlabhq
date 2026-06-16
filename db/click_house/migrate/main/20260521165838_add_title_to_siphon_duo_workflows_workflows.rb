# frozen_string_literal: true

class AddTitleToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN IF NOT EXISTS title Nullable(String);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN IF EXISTS title;
    SQL
  end
end
