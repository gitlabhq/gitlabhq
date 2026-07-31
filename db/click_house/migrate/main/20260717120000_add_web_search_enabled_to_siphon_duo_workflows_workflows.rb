# frozen_string_literal: true

class AddWebSearchEnabledToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN IF NOT EXISTS web_search_enabled Bool DEFAULT false;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN IF EXISTS web_search_enabled;
    SQL
  end
end
