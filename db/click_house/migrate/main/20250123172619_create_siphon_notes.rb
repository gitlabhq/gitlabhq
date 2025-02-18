# frozen_string_literal: true

class CreateSiphonNotes < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_notes
      (
        note Nullable(String),
        noteable_type LowCardinality(String),
        author_id Nullable(Int64),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        project_id Nullable(Int64),
        attachment Nullable(String) DEFAULT '',
        line_code Nullable(String),
        commit_id Nullable(String),
        noteable_id Nullable(Int64),
        system Bool DEFAULT false,
        st_diff Nullable(String),
        updated_by_id Nullable(Int64),
        type LowCardinality(String) DEFAULT '',
        position Nullable(String),
        original_position Nullable(String),
        resolved_at Nullable(DateTime64(6, 'UTC')),
        resolved_by_id Nullable(Int64),
        discussion_id Nullable(String),
        note_html Nullable(String),
        cached_markdown_version Nullable(Int64),
        change_position Nullable(String),
        resolved_by_push Nullable(Bool),
        review_id Nullable(Int64),
        confidential Nullable(Bool),
        last_edited_at Nullable(DateTime64(6, 'UTC')),
        internal Bool DEFAULT false,
        id Int64,
        namespace_id Nullable(Int64),
        imported_from Int8 DEFAULT 0,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_notes
    SQL
  end
end
