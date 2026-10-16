# frozen_string_literal: true

class AddSourceClientToSiphonDuoWorkflowsWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows
        ADD COLUMN IF NOT EXISTS source_client_name LowCardinality(Nullable(String)),
        ADD COLUMN IF NOT EXISTS source_client_version Nullable(String);
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_duo_workflows_workflows
        DROP COLUMN IF EXISTS source_client_name,
        DROP COLUMN IF EXISTS source_client_version;
    SQL
  end
end
