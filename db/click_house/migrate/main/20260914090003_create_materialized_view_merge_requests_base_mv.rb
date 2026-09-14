# frozen_string_literal: true

class CreateMaterializedViewMergeRequestsBaseMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS merge_requests_base_mv
      TO merge_requests_base
      AS
      SELECT
        id,
        target_branch,
        source_branch,
        source_project_id,
        author_id,
        assignee_id,
        title,
        created_at,
        updated_at,
        milestone_id,
        merge_status,
        target_project_id,
        iid,
        description,
        updated_by_id,
        merge_error,
        merge_params,
        merge_when_pipeline_succeeds,
        merge_user_id,
        merge_commit_sha,
        approvals_before_merge,
        rebase_commit_sha,
        in_progress_merge_commit_sha,
        time_estimate,
        squash,
        cached_markdown_version,
        last_edited_at,
        last_edited_by_id,
        merge_jid,
        discussion_locked,
        latest_merge_request_diff_id,
        allow_maintainer_to_push,
        state_id,
        rebase_jid,
        squash_commit_sha,
        merge_ref_sha,
        draft,
        prepared_at,
        merged_commit_sha,
        override_requested_changes,
        head_pipeline_id,
        imported_from,
        retargeted,
        traversal_path,
        _siphon_replicated_at,
        _siphon_deleted
      FROM siphon_merge_requests
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS merge_requests_base_mv'
  end
end
