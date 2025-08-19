# frozen_string_literal: true

class CreateHierarchyAuditEvents < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS hierarchy_audit_events
      (
        traversal_path String,
        id Int64,
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
        created_at DateTime64(6, 'UTC'),
        version DateTime64(6, 'UTC') DEFAULT now(),
        deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (traversal_path, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS hierarchy_audit_events
    SQL
  end
end
