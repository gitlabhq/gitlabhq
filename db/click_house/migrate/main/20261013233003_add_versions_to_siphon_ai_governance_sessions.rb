# frozen_string_literal: true

class AddVersionsToSiphonAiGovernanceSessions < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_ai_governance_sessions
        ADD COLUMN IF NOT EXISTS glab_version Nullable(String),
        ADD COLUMN IF NOT EXISTS agent_version Nullable(String)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE siphon_ai_governance_sessions
        DROP COLUMN IF EXISTS glab_version,
        DROP COLUMN IF EXISTS agent_version
    SQL
  end
end
