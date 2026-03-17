# frozen_string_literal: true

class CreateMaterializedViewMergeRequests < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW merge_requests_mv
      TO merge_requests
      AS
      WITH
        base AS (SELECT * FROM siphon_merge_requests),
        siphon_merge_request_metrics_cte AS (SELECT
          traversal_path,
          merge_request_id,
          id,
          argMax(latest_build_started_at, _siphon_replicated_at) AS latest_build_started_at,
          argMax(latest_build_finished_at, _siphon_replicated_at) AS latest_build_finished_at,
          argMax(first_deployed_to_production_at, _siphon_replicated_at) AS first_deployed_to_production_at,
          argMax(merged_at, _siphon_replicated_at) AS merged_at,
          argMax(merged_by_id, _siphon_replicated_at) AS merged_by_id,
          argMax(latest_closed_by_id, _siphon_replicated_at) AS latest_closed_by_id,
          argMax(latest_closed_at, _siphon_replicated_at) AS latest_closed_at,
          argMax(first_comment_at, _siphon_replicated_at) AS first_comment_at,
          argMax(first_commit_at, _siphon_replicated_at) AS first_commit_at,
          argMax(last_commit_at, _siphon_replicated_at) AS last_commit_at,
          argMax(diff_size, _siphon_replicated_at) AS diff_size,
          argMax(modified_paths_size, _siphon_replicated_at) AS modified_paths_size,
          argMax(commits_count, _siphon_replicated_at) AS commits_count,
          argMax(first_approved_at, _siphon_replicated_at) AS first_approved_at,
          argMax(first_reassigned_at, _siphon_replicated_at) AS first_reassigned_at,
          argMax(added_lines, _siphon_replicated_at) AS added_lines,
          argMax(removed_lines, _siphon_replicated_at) AS removed_lines,
          argMax(first_contribution, _siphon_replicated_at) AS first_contribution,
          argMax(pipeline_id, _siphon_replicated_at) AS pipeline_id,
          argMax(reviewer_first_assigned_at, _siphon_replicated_at) AS reviewer_first_assigned_at,
          argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
        FROM siphon_merge_request_metrics
        WHERE (traversal_path, merge_request_id) IN (SELECT traversal_path, id from base)
        GROUP BY traversal_path, merge_request_id, id
        HAVING deleted = false
        ),
        siphon_merge_request_reviewers_cte AS (SELECT
          traversal_path,
          merge_request_id,
          groupArray((user_id, state, created_at)) AS reviewers
        FROM (
          SELECT
            traversal_path,
            merge_request_id,
            id,
            argMax(user_id, _siphon_replicated_at) AS user_id,
            argMax(state, _siphon_replicated_at) AS state,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_merge_request_reviewers
          WHERE (traversal_path, merge_request_id) IN (SELECT traversal_path, id from base)
          GROUP BY traversal_path, merge_request_id, id
          HAVING deleted = false
        )
        GROUP BY traversal_path, merge_request_id
        ),
        siphon_merge_request_assignees_cte AS (SELECT
          traversal_path,
          merge_request_id,
          groupArray((user_id, created_at)) AS assignees
        FROM (
          SELECT
            traversal_path,
            merge_request_id,
            id,
            argMax(user_id, _siphon_replicated_at) AS user_id,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_merge_request_assignees
          WHERE (traversal_path, merge_request_id) IN (SELECT traversal_path, id from base)
          GROUP BY traversal_path, merge_request_id, id
          HAVING deleted = false
        )
        GROUP BY traversal_path, merge_request_id
        ),
        siphon_approvals_cte AS (SELECT
          traversal_path,
          merge_request_id,
          groupArray((user_id, created_at)) AS approvals
        FROM (
          SELECT
            traversal_path,
            merge_request_id,
            id,
            argMax(user_id, _siphon_replicated_at) AS user_id,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_approvals
          WHERE (traversal_path, merge_request_id) IN (SELECT traversal_path, id from base)
          GROUP BY traversal_path, merge_request_id, id
          HAVING deleted = false
        )
        GROUP BY traversal_path, merge_request_id
        ),
        siphon_label_links_cte AS (SELECT
          traversal_path,
          target_id AS merge_request_id,
          groupArray((label_id, created_at)) AS label_ids
        FROM (
          SELECT
            traversal_path,
            target_type,
            target_id,
            id,
            argMax(label_id, _siphon_replicated_at) AS label_id,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_label_links
          WHERE (traversal_path, target_type, target_id) IN (SELECT traversal_path, 'MergeRequest' AS target_type, id AS target_id from base)
          GROUP BY traversal_path, target_type, target_id, id
          HAVING deleted = false
        )
        GROUP BY traversal_path, target_id
        ),
        siphon_award_emoji_cte AS (SELECT
          traversal_path,
          awardable_id AS merge_request_id,
          groupArray((name, user_id, created_at)) AS award_emojis
        FROM (
          SELECT
            traversal_path,
            awardable_type,
            awardable_id,
            id,
            argMax(name, _siphon_replicated_at) AS name,
            argMax(user_id, _siphon_replicated_at) AS user_id,
            argMax(created_at, _siphon_replicated_at) AS created_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_award_emoji
          WHERE (traversal_path, awardable_type, awardable_id) IN (SELECT traversal_path, 'MergeRequest' AS awardable_type, id AS awardable_id from base)
          GROUP BY traversal_path, awardable_type, awardable_id, id
          HAVING deleted = false
        )
        GROUP BY traversal_path, awardable_id
        )
      SELECT
        base.id AS id,
        base.target_branch AS target_branch,
        base.source_branch AS source_branch,
        base.source_project_id AS source_project_id,
        base.author_id AS author_id,
        base.assignee_id AS assignee_id,
        base.title AS title,
        base.created_at AS created_at,
        base.updated_at AS updated_at,
        base.milestone_id AS milestone_id,
        base.merge_status AS merge_status,
        base.target_project_id AS target_project_id,
        base.iid AS iid,
        base.description AS description,
        base.updated_by_id AS updated_by_id,
        base.merge_error AS merge_error,
        base.merge_params AS merge_params,
        base.merge_when_pipeline_succeeds AS merge_when_pipeline_succeeds,
        base.merge_user_id AS merge_user_id,
        base.merge_commit_sha AS merge_commit_sha,
        base.approvals_before_merge AS approvals_before_merge,
        base.rebase_commit_sha AS rebase_commit_sha,
        base.in_progress_merge_commit_sha AS in_progress_merge_commit_sha,
        base.time_estimate AS time_estimate,
        base.squash AS squash,
        base.cached_markdown_version AS cached_markdown_version,
        base.last_edited_at AS last_edited_at,
        base.last_edited_by_id AS last_edited_by_id,
        base.merge_jid AS merge_jid,
        base.discussion_locked AS discussion_locked,
        base.latest_merge_request_diff_id AS latest_merge_request_diff_id,
        base.allow_maintainer_to_push AS allow_maintainer_to_push,
        base.state_id AS state_id,
        base.rebase_jid AS rebase_jid,
        base.squash_commit_sha AS squash_commit_sha,
        base.merge_ref_sha AS merge_ref_sha,
        base.draft AS draft,
        base.prepared_at AS prepared_at,
        base.merged_commit_sha AS merged_commit_sha,
        base.override_requested_changes AS override_requested_changes,
        base.head_pipeline_id AS head_pipeline_id,
        base.imported_from AS imported_from,
        base.retargeted AS retargeted,
        base.traversal_path AS traversal_path,
        base._siphon_replicated_at AS _siphon_replicated_at,
        base._siphon_deleted AS _siphon_deleted,
        siphon_merge_request_metrics_cte.latest_build_started_at AS metric_latest_build_started_at,
        siphon_merge_request_metrics_cte.latest_build_finished_at AS metric_latest_build_finished_at,
        siphon_merge_request_metrics_cte.first_deployed_to_production_at AS metric_first_deployed_to_production_at,
        siphon_merge_request_metrics_cte.merged_at AS metric_merged_at,
        siphon_merge_request_metrics_cte.merged_by_id AS metric_merged_by_id,
        siphon_merge_request_metrics_cte.latest_closed_by_id AS metric_latest_closed_by_id,
        siphon_merge_request_metrics_cte.latest_closed_at AS metric_latest_closed_at,
        siphon_merge_request_metrics_cte.first_comment_at AS metric_first_comment_at,
        siphon_merge_request_metrics_cte.first_commit_at AS metric_first_commit_at,
        siphon_merge_request_metrics_cte.last_commit_at AS metric_last_commit_at,
        siphon_merge_request_metrics_cte.diff_size AS metric_diff_size,
        siphon_merge_request_metrics_cte.modified_paths_size AS metric_modified_paths_size,
        siphon_merge_request_metrics_cte.commits_count AS metric_commits_count,
        siphon_merge_request_metrics_cte.first_approved_at AS metric_first_approved_at,
        siphon_merge_request_metrics_cte.first_reassigned_at AS metric_first_reassigned_at,
        siphon_merge_request_metrics_cte.added_lines AS metric_added_lines,
        siphon_merge_request_metrics_cte.removed_lines AS metric_removed_lines,
        siphon_merge_request_metrics_cte.first_contribution AS metric_first_contribution,
        siphon_merge_request_metrics_cte.pipeline_id AS metric_pipeline_id,
        siphon_merge_request_metrics_cte.reviewer_first_assigned_at AS metric_reviewer_first_assigned_at,
        siphon_merge_request_reviewers_cte.reviewers AS reviewers,
        siphon_merge_request_assignees_cte.assignees AS assignees,
        siphon_approvals_cte.approvals AS approvals,
        siphon_label_links_cte.label_ids AS label_ids,
        siphon_award_emoji_cte.award_emojis AS award_emojis
      FROM base
      LEFT JOIN siphon_merge_request_metrics_cte ON base.traversal_path = siphon_merge_request_metrics_cte.traversal_path AND
base.id = siphon_merge_request_metrics_cte.merge_request_id

      LEFT JOIN siphon_merge_request_reviewers_cte ON base.traversal_path = siphon_merge_request_reviewers_cte.traversal_path AND
base.id = siphon_merge_request_reviewers_cte.merge_request_id

      LEFT JOIN siphon_merge_request_assignees_cte ON base.traversal_path = siphon_merge_request_assignees_cte.traversal_path AND
base.id = siphon_merge_request_assignees_cte.merge_request_id

      LEFT JOIN siphon_approvals_cte ON base.traversal_path = siphon_approvals_cte.traversal_path AND
base.id = siphon_approvals_cte.merge_request_id

      LEFT JOIN siphon_label_links_cte ON base.traversal_path = siphon_label_links_cte.traversal_path AND
base.id = siphon_label_links_cte.merge_request_id

      LEFT JOIN siphon_award_emoji_cte ON base.traversal_path = siphon_award_emoji_cte.traversal_path AND
base.id = siphon_award_emoji_cte.merge_request_id

    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS merge_requests_mv'
  end
end
