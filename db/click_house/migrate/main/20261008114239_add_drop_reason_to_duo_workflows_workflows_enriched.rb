# frozen_string_literal: true

class AddDropReasonToDuoWorkflowsWorkflowsEnriched < ClickHouse::Migration
  def up
    execute <<~SQL
    ALTER TABLE duo_workflows_workflows_enriched
      ADD COLUMN IF NOT EXISTS drop_reason LowCardinality(Nullable(String)) AFTER execution_mode;
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE duo_workflows_workflows_enriched
      DROP COLUMN IF EXISTS drop_reason;
    SQL
  end
end
