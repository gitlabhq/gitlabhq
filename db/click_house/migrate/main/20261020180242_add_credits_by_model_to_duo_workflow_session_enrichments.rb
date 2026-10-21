# frozen_string_literal: true

class AddCreditsByModelToDuoWorkflowSessionEnrichments < ClickHouse::Migration
  # Decimal64(4) matches CustomersDot's column, so per-model totals compare exactly.
  def up
    execute <<~SQL
    ALTER TABLE duo_workflow_session_enrichments
      ADD COLUMN IF NOT EXISTS credits_by_model Map(LowCardinality(String), Decimal64(4)) CODEC(ZSTD(1))
      AFTER model_used;
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE duo_workflow_session_enrichments
      DROP COLUMN IF EXISTS credits_by_model;
    SQL
  end
end
