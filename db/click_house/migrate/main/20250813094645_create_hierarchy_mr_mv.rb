# frozen_string_literal: true

class CreateHierarchyMrMv < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS hierarchy_merge_requests_mv TO hierarchy_merge_requests
      AS WITH
          cte AS
          (
              SELECT *
              FROM siphon_merge_requests
          ),
          project_namespace_paths AS
          (
              SELECT * FROM (
                SELECT
                    id,
                    argMax(traversal_path, version) AS traversal_path,
                    argMax(deleted, version) AS deleted
                FROM project_namespace_traversal_paths
                WHERE id IN (
                    SELECT DISTINCT target_project_id
                    FROM cte
                )
                GROUP BY id
              ) WHERE deleted = false
          ),
          collected_label_ids AS
          (
            SELECT merge_request_id, concat('/', arrayStringConcat(arraySort(groupArray(label_id)), '/'), '/') AS label_ids
            FROM (
              SELECT
                merge_request_id,
                label_id,
                id,
                argMax(deleted, version) AS deleted
              FROM merge_request_label_links
              WHERE merge_request_id IN (SELECT id FROM cte)
              GROUP BY merge_request_id, label_id, id
            ) WHERE deleted = false
            GROUP BY merge_request_id
          ),
          collected_assignee_ids AS
          (
            SELECT merge_request_id, concat('/', arrayStringConcat(arraySort(groupArray(user_id)), '/'), '/') AS user_ids
            FROM (
              SELECT
                merge_request_id,
                user_id,
                argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
              FROM siphon_merge_request_assignees
              WHERE merge_request_id IN (SELECT id FROM cte)
              GROUP BY merge_request_id, user_id
            ) WHERE _siphon_deleted = false
            GROUP BY merge_request_id
          ),
          collected_approver_ids AS
          (
            SELECT merge_request_id, concat('/', arrayStringConcat(arraySort(groupArray(user_id)), '/'), '/') AS user_ids
            FROM (
              SELECT
                merge_request_id,
                user_id,
                argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
              FROM siphon_approvals
              WHERE merge_request_id IN (SELECT id FROM cte)
              GROUP BY merge_request_id, user_id
            ) WHERE _siphon_deleted = false
            GROUP BY merge_request_id
          ),
          collected_merge_request_metrics AS
          (
            SELECT *
            FROM (
              SELECT
                merge_request_id,
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
                argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
              FROM siphon_merge_request_metrics
              GROUP BY merge_request_id, id
            ) WHERE _siphon_deleted = false
          )
          SELECT
              -- handle the case where namespace_id is null
              multiIf(cte.target_project_id != 0, project_namespace_paths.traversal_path, '0/') AS traversal_path,
              cte.id AS id,
              cte.target_branch AS target_branch,
              cte.source_branch AS source_branch,
              cte.source_project_id AS source_project_id,
              cte.author_id AS author_id,
              cte.assignee_id AS assignee_id,
              cte.title AS title,
              cte.created_at AS created_at,
              cte.updated_at AS updated_at,
              cte.milestone_id AS milestone_id,
              cte.merge_status AS merge_status,
              cte.target_project_id AS target_project_id,
              cte.iid AS iid,
              cte.description AS description,
              cte.updated_by_id AS updated_by_id,
              cte.merge_error AS merge_error,
              cte.merge_params AS merge_params,
              cte.merge_when_pipeline_succeeds AS merge_when_pipeline_succeeds,
              cte.merge_user_id AS merge_user_id,
              cte.merge_commit_sha AS merge_commit_sha,
              cte.approvals_before_merge AS approvals_before_merge,
              cte.rebase_commit_sha AS rebase_commit_sha,
              cte.in_progress_merge_commit_sha AS in_progress_merge_commit_sha,
              cte.lock_version AS lock_version,
              cte.time_estimate AS time_estimate,
              cte.squash AS squash,
              cte.cached_markdown_version AS cached_markdown_version,
              cte.last_edited_at AS last_edited_at,
              cte.last_edited_by_id AS last_edited_by_id,
              cte.merge_jid AS merge_jid,
              cte.discussion_locked AS discussion_locked,
              cte.latest_merge_request_diff_id AS latest_merge_request_diff_id,
              cte.allow_maintainer_to_push AS allow_maintainer_to_push,
              cte.state_id AS state_id,
              cte.rebase_jid AS rebase_jid,
              cte.squash_commit_sha AS squash_commit_sha,
              cte.sprint_id AS sprint_id,
              cte.merge_ref_sha AS merge_ref_sha,
              cte.draft AS draft,
              cte.prepared_at AS prepared_at,
              cte.merged_commit_sha AS merged_commit_sha,
              cte.override_requested_changes AS override_requested_changes,
              cte.head_pipeline_id AS head_pipeline_id,
              cte.imported_from AS imported_from,
              cte.retargeted AS retargeted,
              cte._siphon_replicated_at AS version,
              cte._siphon_deleted AS deleted,
              collected_label_ids.label_ids AS label_ids,
              collected_assignee_ids.user_ids AS assignee_ids,
              collected_approver_ids.user_ids AS approver_ids,
              collected_merge_request_metrics.latest_build_started_at AS metric_latest_build_started_at,
              collected_merge_request_metrics.latest_build_finished_at AS metric_latest_build_finished_at,
              collected_merge_request_metrics.first_deployed_to_production_at AS metric_first_deployed_to_production_at,
              collected_merge_request_metrics.merged_at AS metric_merged_at,
              collected_merge_request_metrics.merged_by_id AS metric_merged_by_id,
              collected_merge_request_metrics.latest_closed_by_id AS metric_latest_closed_by_id,
              collected_merge_request_metrics.latest_closed_at AS metric_latest_closed_at,
              collected_merge_request_metrics.first_comment_at AS metric_first_comment_at,
              collected_merge_request_metrics.first_commit_at AS metric_first_commit_at,
              collected_merge_request_metrics.last_commit_at AS metric_last_commit_at,
              collected_merge_request_metrics.diff_size AS metric_diff_size,
              collected_merge_request_metrics.modified_paths_size AS metric_modified_paths_size,
              collected_merge_request_metrics.commits_count AS metric_commits_count,
              collected_merge_request_metrics.first_approved_at AS metric_first_approved_at,
              collected_merge_request_metrics.first_reassigned_at AS metric_first_reassigned_at,
              collected_merge_request_metrics.added_lines AS metric_added_lines,
              collected_merge_request_metrics.removed_lines AS metric_removed_lines,
              collected_merge_request_metrics.first_contribution AS metric_first_contribution,
              collected_merge_request_metrics.pipeline_id AS metric_pipeline_id,
              collected_merge_request_metrics.reviewer_first_assigned_at AS metric_reviewer_first_assigned_at
          FROM cte
          LEFT JOIN project_namespace_paths ON project_namespace_paths.id = cte.target_project_id
          LEFT JOIN collected_assignee_ids ON collected_assignee_ids.merge_request_id = cte.id
          LEFT JOIN collected_label_ids ON collected_label_ids.merge_request_id = cte.id
          LEFT JOIN collected_approver_ids ON collected_approver_ids.merge_request_id = cte.id
          LEFT JOIN collected_merge_request_metrics ON collected_merge_request_metrics.merge_request_id = cte.id
    SQL
  end

  def down
    execute "DROP VIEW IF EXISTS hierarchy_merge_requests_mv"
  end
end
