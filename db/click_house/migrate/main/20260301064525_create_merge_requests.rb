# frozen_string_literal: true

class CreateMergeRequests < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS merge_requests
      (
        id Int64 CODEC(DoubleDelta, ZSTD),
        target_branch String,
        source_branch String,
        source_project_id Nullable(Int64),
        author_id Nullable(Int64),
        assignee_id Nullable(Int64),
        title String CODEC(ZSTD(1)),
        created_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD(1)),
        milestone_id Nullable(Int64),
        merge_status LowCardinality(String) DEFAULT 'unchecked',
        target_project_id Int64,
        iid Int64,
        description String CODEC(ZSTD(3)),
        updated_by_id Nullable(Int64),
        merge_error Nullable(String),
        merge_params Nullable(String),
        merge_when_pipeline_succeeds Bool DEFAULT false CODEC(ZSTD(1)),
        merge_user_id Nullable(Int64),
        merge_commit_sha Nullable(String),
        approvals_before_merge Nullable(Int64),
        rebase_commit_sha Nullable(String),
        in_progress_merge_commit_sha Nullable(String),
        time_estimate Nullable(Int64) DEFAULT 0,
        squash Bool DEFAULT false CODEC(ZSTD(1)),
        cached_markdown_version Nullable(Int64),
        last_edited_at Nullable(DateTime64(6, 'UTC')),
        last_edited_by_id Nullable(Int64),
        merge_jid String,
        discussion_locked Nullable(Bool) CODEC(ZSTD(1)),
        latest_merge_request_diff_id Nullable(Int64),
        allow_maintainer_to_push Nullable(Bool) DEFAULT true CODEC(ZSTD(1)),
        state_id Int16 DEFAULT 1,
        rebase_jid Nullable(String),
        squash_commit_sha Nullable(String),
        merge_ref_sha Nullable(String),
        draft Bool DEFAULT false CODEC(ZSTD(1)),
        prepared_at Nullable(DateTime64(6, 'UTC')),
        merged_commit_sha Nullable(String),
        override_requested_changes Bool DEFAULT false CODEC(ZSTD(1)),
        head_pipeline_id Nullable(Int64),
        imported_from Int16 DEFAULT 0,
        retargeted Bool DEFAULT false CODEC(ZSTD(1)),
        traversal_path String DEFAULT multiIf(coalesce(target_project_id, 0) != 0, dictGetOrDefault('project_traversal_paths_dict', 'traversal_path', target_project_id, '0/'), '0/') CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now() CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT FALSE CODEC(ZSTD(1)),
        metric_latest_build_started_at Nullable(DateTime64(6, 'UTC')),
        metric_latest_build_finished_at Nullable(DateTime64(6, 'UTC')),
        metric_first_deployed_to_production_at Nullable(DateTime64(6, 'UTC')),
        metric_merged_at Nullable(DateTime64(6, 'UTC')),
        metric_merged_by_id Nullable(Int64),
        metric_latest_closed_by_id Nullable(Int64),
        metric_latest_closed_at Nullable(DateTime64(6, 'UTC')),
        metric_first_comment_at Nullable(DateTime64(6, 'UTC')),
        metric_first_commit_at Nullable(DateTime64(6, 'UTC')),
        metric_last_commit_at Nullable(DateTime64(6, 'UTC')),
        metric_diff_size Nullable(Int64),
        metric_modified_paths_size Nullable(Int64),
        metric_commits_count Nullable(Int64),
        metric_first_approved_at Nullable(DateTime64(6, 'UTC')),
        metric_first_reassigned_at Nullable(DateTime64(6, 'UTC')),
        metric_added_lines Nullable(Int64),
        metric_removed_lines Nullable(Int64),
        metric_first_contribution Bool DEFAULT false,
        metric_pipeline_id Nullable(Int64),
        metric_reviewer_first_assigned_at Nullable(DateTime64(6, 'UTC')),
        reviewers Array(Tuple(user_id UInt64, state Int16, created_at DateTime64(6, 'UTC'))),
        assignees Array(Tuple(user_id UInt64, created_at DateTime64(6, 'UTC'))),
        approvals Array(Tuple(user_id UInt64, created_at DateTime64(6, 'UTC'))),
        label_ids Array(Tuple(label_id UInt64, created_at DateTime64(6, 'UTC'))),
        award_emojis Array(Tuple(name String, user_id UInt64, created_at DateTime64(6, 'UTC'))),
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
      DROP TABLE IF EXISTS merge_requests
    SQL
  end
end
