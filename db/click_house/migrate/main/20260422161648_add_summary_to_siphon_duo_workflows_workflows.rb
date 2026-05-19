# frozen_string_literal: true

class AddSummaryToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows ADD COLUMN summary Nullable(String);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows DROP COLUMN summary;
    SQL
  end
end
