# frozen_string_literal: true

class AddAiGovernanceSessionIdToClickHouseAiAuditEvents < ClickHouse::Migration
  # A `SELECT *` projection breaks every later mutation once a column is added, under
  # deduplicate_merge_projection_mode = 'rebuild' (see !225458). So drop by_workflow_id
  # first and use explicit columns; the _v2 name avoids racing the async DROP.
  COLUMNS = %w[
    id
    event_name
    created_at
    author_id
    project_id
    group_id
    ip_address
    workflow_id
    details
    traversal_path
    ai_governance_session_id
  ].join(', ')

  def up
    execute <<~SQL
      ALTER TABLE ai_audit_events DROP PROJECTION IF EXISTS by_workflow_id
      SETTINGS mutations_sync = 0
    SQL

    execute <<~SQL
      ALTER TABLE ai_audit_events
      ADD COLUMN IF NOT EXISTS ai_governance_session_id UInt64 DEFAULT 0 CODEC(DoubleDelta, ZSTD)
    SQL

    add_projection('by_workflow_id_v2', 'workflow_id, created_at, id')
    add_projection('by_ai_governance_session_id', 'ai_governance_session_id, created_at, id')
  end

  def down
    %w[by_ai_governance_session_id by_workflow_id_v2].each do |name|
      execute <<~SQL
        ALTER TABLE ai_audit_events DROP PROJECTION IF EXISTS #{name}
        SETTINGS mutations_sync = 0
      SQL
    end

    execute <<~SQL
      ALTER TABLE ai_audit_events DROP COLUMN IF EXISTS ai_governance_session_id
    SQL

    execute <<~SQL
      ALTER TABLE ai_audit_events
      ADD PROJECTION IF NOT EXISTS by_workflow_id (
        SELECT *
        ORDER BY workflow_id, created_at, id
      )
    SQL

    execute <<~SQL
      ALTER TABLE ai_audit_events MATERIALIZE PROJECTION by_workflow_id
      SETTINGS mutations_sync = 0
    SQL
  end

  private

  def add_projection(name, order_by)
    execute <<~SQL
      ALTER TABLE ai_audit_events
      ADD PROJECTION IF NOT EXISTS #{name} (
        SELECT #{COLUMNS}
        ORDER BY #{order_by}
      )
    SQL

    execute <<~SQL
      ALTER TABLE ai_audit_events MATERIALIZE PROJECTION #{name}
      SETTINGS mutations_sync = 0
    SQL
  end
end
