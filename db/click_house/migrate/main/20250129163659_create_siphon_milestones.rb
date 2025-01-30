# frozen_string_literal: true

class CreateSiphonMilestones < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_milestones
      (
        id Int64,
        title String,
        project_id Nullable(Int64),
        description Nullable(String),
        due_date Nullable(Date32),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        state LowCardinality(String) DEFAULT '',
        iid Nullable(Int64),
        title_html Nullable(String),
        description_html Nullable(String),
        start_date Nullable(Date32),
        cached_markdown_version Nullable(Int64),
        group_id Nullable(Int64),
        lock_version Int64 DEFAULT 0,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_milestones
    SQL
  end
end
