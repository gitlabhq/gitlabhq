# frozen_string_literal: true

class CreateWorkItems < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS work_items
      (
        id Int64 CODEC(Delta, ZSTD),
        title String CODEC(ZSTD(3)),
        author_id Nullable(Int64),
        project_id Nullable(Int64),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        description String CODEC(ZSTD(3)),
        milestone_id Nullable(Int64),
        iid Int64,
        updated_by_id Nullable(Int64),
        weight Nullable(Int64),
        confidential Bool DEFAULT false CODEC(ZSTD(1)),
        due_date Nullable(Date32),
        moved_to_id Nullable(Int64),
        time_estimate Nullable(Int64) DEFAULT 0,
        relative_position Nullable(Int64),
        service_desk_reply_to Nullable(String),
        cached_markdown_version Nullable(Int64),
        last_edited_at Nullable(DateTime64(6, 'UTC')),
        last_edited_by_id Nullable(Int64),
        discussion_locked Nullable(Bool) CODEC(ZSTD(1)),
        closed_at Nullable(DateTime64(6, 'UTC')),
        closed_by_id Nullable(Int64),
        state_id Int16 DEFAULT 1,
        duplicated_to_id Nullable(Int64),
        promoted_to_epic_id Nullable(Int64),
        health_status Nullable(Int16),
        sprint_id Nullable(Int64),
        blocking_issues_count Int64 DEFAULT 0,
        upvotes_count Int64 DEFAULT 0,
        work_item_type_id Int64,
        namespace_id Int64,
        start_date Nullable(Date32),
        imported_from Int16 DEFAULT 0,
        namespace_traversal_ids Array(Int64) DEFAULT [],
        traversal_path String DEFAULT multiIf(coalesce(namespace_id, 0) != 0, dictGetOrDefault('namespace_traversal_paths_dict', 'traversal_path', namespace_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6) CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        metric_first_mentioned_in_commit_at Nullable(DateTime64(6, 'UTC')),
        metric_first_associated_with_milestone_at Nullable(DateTime64(6, 'UTC')),
        metric_first_added_to_board_at Nullable(DateTime64(6, 'UTC')),
        assignees Array(UInt64),
        label_ids Array(Tuple(label_id UInt64, created_at DateTime64(6, 'UTC'))),
        award_emojis Array(Tuple(name String, user_id UInt64, created_at DateTime64(6, 'UTC'))),
        system_defined_status_id Nullable(Int64),
        custom_status_id Nullable(Int64),
        PROJECTION pg_pkey_ordered (
          SELECT *
          ORDER BY id
        )
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      SETTINGS index_granularity = 2048, deduplicate_merge_projection_mode = 'rebuild'
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS work_items
    SQL
  end
end
