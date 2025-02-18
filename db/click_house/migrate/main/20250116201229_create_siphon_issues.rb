# frozen_string_literal: true

class CreateSiphonIssues < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_issues
      (
        id Int64,
        title Nullable(String),
        author_id Nullable(Int64),
        project_id Nullable(Int64),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        description Nullable(String),
        milestone_id Nullable(Int64),
        iid Nullable(Int64),
        updated_by_id Nullable(Int64),
        weight Nullable(Int64),
        confidential Bool DEFAULT false,
        due_date Nullable(Date32),
        moved_to_id Nullable(Int64),
        lock_version Nullable(Int64) DEFAULT 0,
        title_html Nullable(String),
        description_html Nullable(String),
        time_estimate Nullable(Int64) DEFAULT 0,
        relative_position Nullable(Int64),
        service_desk_reply_to Nullable(String),
        cached_markdown_version Nullable(Int64),
        last_edited_at Nullable(DateTime64(6, 'UTC')),
        last_edited_by_id Nullable(Int64),
        discussion_locked Nullable(Bool),
        closed_at Nullable(DateTime64(6, 'UTC')),
        closed_by_id Nullable(Int64),
        state_id Int8 DEFAULT 1,
        duplicated_to_id Nullable(Int64),
        promoted_to_epic_id Nullable(Int64),
        health_status Nullable(Int8),
        external_key Nullable(String),
        sprint_id Nullable(Int64),
        blocking_issues_count Int64 DEFAULT 0,
        upvotes_count Int64 DEFAULT 0,
        work_item_type_id Nullable(Int64),
        namespace_id Nullable(Int64),
        start_date Nullable(Date32),
        tmp_epic_id Nullable(Int64),
        imported_from Int8 DEFAULT 0,
        correct_work_item_type_id Int64,
        author_id_convert_to_bigint Nullable(Int64),
        closed_by_id_convert_to_bigint Nullable(Int64),
        duplicated_to_id_convert_to_bigint Nullable(Int64),
        id_convert_to_bigint Int64 DEFAULT 0,
        last_edited_by_id_convert_to_bigint Nullable(Int64),
        milestone_id_convert_to_bigint Nullable(Int64),
        moved_to_id_convert_to_bigint Nullable(Int64),
        project_id_convert_to_bigint Nullable(Int64),
        promoted_to_epic_id_convert_to_bigint Nullable(Int64),
        updated_by_id_convert_to_bigint Nullable(Int64),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_issues
    SQL
  end
end
