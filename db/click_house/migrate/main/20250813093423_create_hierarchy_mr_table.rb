# frozen_string_literal: true

class CreateHierarchyMrTable < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS hierarchy_merge_requests
      (
        traversal_path String,
        id Int64,
        target_branch String,
        source_branch String,
        source_project_id Nullable(Int64),
        author_id Nullable(Int64),
        assignee_id Nullable(Int64),
        title String DEFAULT '',
        created_at DateTime64(6, 'UTC') DEFAULT now(),
        updated_at DateTime64(6, 'UTC') DEFAULT now(),
        milestone_id Nullable(Int64),
        merge_status LowCardinality(String) DEFAULT 'unchecked',
        target_project_id Int64,
        iid Nullable(Int64),
        description String DEFAULT '',
        updated_by_id Nullable(Int64),
        merge_error Nullable(String),
        merge_params Nullable(String),
        merge_when_pipeline_succeeds Bool DEFAULT false,
        merge_user_id Nullable(Int64),
        merge_commit_sha Nullable(String),
        approvals_before_merge Nullable(Int64),
        rebase_commit_sha Nullable(String),
        in_progress_merge_commit_sha Nullable(String),
        lock_version Int64 DEFAULT 0,
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
        label_ids String DEFAULT '',
        assignee_ids String DEFAULT '',
        approver_ids String DEFAULT '',
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
        version DateTime64(6, 'UTC') DEFAULT now(),
        deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (traversal_path, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS hierarchy_merge_requests
    SQL
  end
end
