# frozen_string_literal: true

class CreateSiphonOrganizations < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_organizations
      (
        id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        name String DEFAULT '',
        path String DEFAULT '',
        visibility_level Int8 DEFAULT 0,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
      SETTINGS index_granularity = 512
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_organizations
    SQL
  end
end
