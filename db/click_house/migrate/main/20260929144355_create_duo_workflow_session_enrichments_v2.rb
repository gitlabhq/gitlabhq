# frozen_string_literal: true

class CreateDuoWorkflowSessionEnrichmentsV2 < ClickHouse::Migration
  # Decimal64(4) matches CustomersDot's column, so totals compare exactly.
  # No DEFAULT on updated_at: the version column holds CustomersDot's clock, and a local now() would win every merge.
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS duo_workflow_session_enrichments_v2
      (
        workflow_id Int64 CODEC(DoubleDelta, ZSTD(1)),
        credits_used Decimal64(4) DEFAULT 0 CODEC(ZSTD(1)),
        model_used LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
        credits_by_model Map(LowCardinality(String), Decimal64(4)) CODEC(ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(updated_at)
      ORDER BY workflow_id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS duo_workflow_session_enrichments_v2
    SQL
  end
end
