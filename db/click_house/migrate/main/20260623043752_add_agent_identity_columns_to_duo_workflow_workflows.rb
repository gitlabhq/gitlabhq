# frozen_string_literal: true

class AddAgentIdentityColumnsToDuoWorkflowWorkflows < ClickHouse::Migration
  def up
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      ADD COLUMN IF NOT EXISTS agent_type Nullable(String),
      ADD COLUMN IF NOT EXISTS jsonl_sha256 Nullable(String),
      ADD COLUMN IF NOT EXISTS idempotency_key Nullable(String),
      ADD COLUMN IF NOT EXISTS sync_type Nullable(Int16),
      ADD COLUMN IF NOT EXISTS agent_identity_id Nullable(Int64);
    SQL
  end

  def down
    execute <<~SQL
    ALTER TABLE siphon_duo_workflows_workflows
      DROP COLUMN IF EXISTS agent_type,
      DROP COLUMN IF EXISTS jsonl_sha256,
      DROP COLUMN IF EXISTS idempotency_key,
      DROP COLUMN IF EXISTS sync_type,
      DROP COLUMN IF EXISTS agent_identity_id;
    SQL
  end
end
