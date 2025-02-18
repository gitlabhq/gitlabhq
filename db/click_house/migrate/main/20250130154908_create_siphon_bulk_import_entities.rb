# frozen_string_literal: true

class CreateSiphonBulkImportEntities < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_bulk_import_entities
      (
        id Int64,
        bulk_import_id Int64,
        parent_id Nullable(Int64),
        namespace_id Nullable(Int64),
        project_id Nullable(Int64),
        source_type Int8,
        source_full_path String,
        destination_name String,
        destination_namespace String,
        status Int8,
        jid Nullable(String),
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        source_xid Nullable(Int64),
        migrate_projects Bool DEFAULT true,
        has_failures Nullable(Bool) DEFAULT false,
        migrate_memberships Bool DEFAULT true,
        organization_id Nullable(Int64),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_bulk_import_entities
    SQL
  end
end
