# frozen_string_literal: true

class CreateDuoWorkflowSessionEnrichments < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS duo_workflow_session_enrichments
      (
        workflow_id UInt64 CODEC(DoubleDelta, ZSTD(1)),
        credits_used Float64 DEFAULT 0 CODEC(ZSTD(1)),
        model_used LowCardinality(String) DEFAULT '' CODEC(ZSTD(1)),
        updated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta(8), ZSTD(1))
      )
      ENGINE = ReplacingMergeTree(updated_at)
      ORDER BY (workflow_id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS duo_workflow_session_enrichments
    SQL
  end
end
