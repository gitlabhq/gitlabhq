# frozen_string_literal: true

class CreateSiphonGroupAuditEvents < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_group_audit_events
      (
        id Int64,
        created_at DateTime64(6, 'UTC'),
        group_id Int64,
        author_id Int64,
        target_id Int64,
        event_name String DEFAULT '',
        details String DEFAULT '',
        ip_address String DEFAULT '',
        author_name String DEFAULT '',
        entity_path String DEFAULT '',
        target_details String DEFAULT '',
        target_type String DEFAULT '',
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_group_audit_events
    SQL
  end
end
