# frozen_string_literal: true

class ReAddAiGovernanceSessionIdToClickHouseAiAuditEvents < ClickHouse::Migration
  # ALTERs retry while ClickHouse reports a running mutation (CANNOT_ASSIGN_ALTER / not finished), because migrations
  # can't read system.mutations and a synchronous wait can outlast the 20s HTTP read timeout.
  # See https://gitlab.com/gitlab-com/gl-infra/production/-/work_items/23053.
  TableBusyError = Class.new(StandardError)

  BUSY_ERROR = /CANNOT_ASSIGN_ALTER|affected by mutation .* which is not finished yet/

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

  PROJECTIONS = {
    'by_workflow_id_v2' => 'workflow_id, created_at, id',
    'by_ai_governance_session_id' => 'ai_governance_session_id, created_at, id'
  }.freeze

  def up
    # A `SELECT *` projection breaks every later mutation once a column is added, under
    # deduplicate_merge_projection_mode = 'rebuild'. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225458.
    drop_projection('by_workflow_id')

    execute_when_idle <<~SQL
      ALTER TABLE ai_audit_events
      ADD COLUMN IF NOT EXISTS ai_governance_session_id UInt64 DEFAULT 0 CODEC(DoubleDelta, ZSTD)
    SQL

    PROJECTIONS.each do |name, order_by|
      execute_when_idle <<~SQL
        ALTER TABLE ai_audit_events
        ADD PROJECTION IF NOT EXISTS #{name} (
          SELECT #{COLUMNS}
          ORDER BY #{order_by}
        )
      SQL
    end

    # These run async (87M rows on GitLab.com), so any later ALTER migration on this table must wait for them.
    PROJECTIONS.each_key { |name| materialize_projection(name) }
  end

  def down
    PROJECTIONS.each_key { |name| drop_projection(name) }

    execute_when_idle <<~SQL
      ALTER TABLE ai_audit_events DROP COLUMN IF EXISTS ai_governance_session_id
    SQL

    execute_when_idle <<~SQL
      ALTER TABLE ai_audit_events
      ADD PROJECTION IF NOT EXISTS by_workflow_id (
        SELECT *
        ORDER BY workflow_id, created_at, id
      )
    SQL

    materialize_projection('by_workflow_id')
  end

  private

  def drop_projection(name)
    execute_when_idle <<~SQL
      ALTER TABLE ai_audit_events DROP PROJECTION IF EXISTS #{name}
      SETTINGS mutations_sync = 0
    SQL
  end

  def materialize_projection(name)
    execute_when_idle <<~SQL
      ALTER TABLE ai_audit_events MATERIALIZE PROJECTION #{name}
      SETTINGS mutations_sync = 0
    SQL
  end

  def execute_when_idle(sql, timeout: 2.minutes, interval: 5.seconds)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_i

    begin
      execute(sql)
    rescue ClickHouse::Client::DatabaseError => e
      raise unless BUSY_ERROR.match?(e.message)

      if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        raise TableBusyError,
          "ai_audit_events still has a running mutation after #{timeout.inspect} (#{e.message.strip}). " \
            "Wait for it to finish and re-run the migration."
      end

      sleep interval
      retry
    end
  end
end
