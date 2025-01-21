# frozen_string_literal: true

class CreateSiphonMergeRequests < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_merge_requests
      (
        id Int64,
        target_branch String,
        source_branch String,
        source_project_id Nullable(Int64),
        author_id Nullable(Int64),
        assignee_id Nullable(Int64),
        title Nullable(String),
        created_at Nullable(DateTime64(6, 'UTC')),
        updated_at Nullable(DateTime64(6, 'UTC')),
        milestone_id Nullable(Int64),
        merge_status LowCardinality(String) DEFAULT 'unchecked',
        target_project_id Int64,
        iid Nullable(Int64),
        description Nullable(String),
        updated_by_id Nullable(Int64),
        merge_error Nullable(String),
        merge_params Nullable(String),
        merge_when_pipeline_succeeds Bool DEFAULT false,
        merge_user_id Nullable(Int64),
        merge_commit_sha Nullable(String),
        approvals_before_merge Nullable(Int64),
        rebase_commit_sha Nullable(String),
        in_progress_merge_commit_sha Nullable(String),
        lock_version Nullable(Int64) DEFAULT 0,
        title_html Nullable(String),
        description_html Nullable(String),
        time_estimate Nullable(Int64) DEFAULT 0,
        squash Bool DEFAULT false,
        cached_markdown_version Nullable(Int64),
        last_edited_at Nullable(DateTime64(6, 'UTC')),
        last_edited_by_id Nullable(Int64),
        merge_jid Nullable(String),
        discussion_locked Nullable(Bool),
        latest_merge_request_diff_id Nullable(Int64),
        allow_maintainer_to_push Nullable(Bool) DEFAULT true,
        state_id Int8 DEFAULT 1,
        rebase_jid Nullable(String),
        squash_commit_sha Nullable(String),
        sprint_id Nullable(Int64),
        merge_ref_sha Nullable(String),
        draft Bool DEFAULT false,
        prepared_at Nullable(DateTime64(6, 'UTC')),
        merged_commit_sha Nullable(String),
        override_requested_changes Bool DEFAULT false,
        head_pipeline_id Nullable(Int64),
        imported_from Int8 DEFAULT 0,
        retargeted Bool DEFAULT false,
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY id
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_merge_requests
    SQL
  end
end
