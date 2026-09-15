# frozen_string_literal: true

class CreateMergeRequestsBase < ClickHouse::Migration
  def up
    # Rolling buffer of recently changed merge requests, so the enrichment view
    # reads a short window instead of all of merge_requests. Losing rows here is
    # safe: merge_requests still flags anything the enrichment never reached.
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS merge_requests_base
      (
        id Int64 CODEC(DoubleDelta, ZSTD(1)),
        target_branch String,
        source_branch String,
        source_project_id Nullable(Int64),
        author_id Nullable(Int64),
        assignee_id Nullable(Int64),
        title String CODEC(ZSTD(1)),
        created_at DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
        updated_at DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
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
        traversal_path String CODEC(ZSTD(3)),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        _siphon_deleted Bool DEFAULT false CODEC(ZSTD(1)),
        seen DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(ZSTD(1)),
        INDEX idx_merge_requests_base_seen_minmax seen TYPE minmax GRANULARITY 1
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (traversal_path, id)
      TTL seen + INTERVAL 1 HOUR
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS merge_requests_base
    SQL
  end
end
