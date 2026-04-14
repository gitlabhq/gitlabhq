# frozen_string_literal: true

class CreateWorkItemsMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW work_items_mv
      TO work_items
      AS
      WITH
        base AS (SELECT * FROM siphon_issues),
        siphon_work_item_current_statuses_cte AS (
          SELECT
            traversal_path,
            work_item_id,
            id,
            argMax(system_defined_status_id, _siphon_replicated_at) AS system_defined_status_id,
            argMax(custom_status_id, _siphon_replicated_at) AS custom_status_id,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_work_item_current_statuses
          WHERE (traversal_path, work_item_id) IN (SELECT traversal_path, id FROM base)
          GROUP BY ALL
          HAVING deleted = false
        ),
        siphon_issue_metrics_cte AS (
          SELECT
            traversal_path,
            issue_id,
            id,
            argMax(first_mentioned_in_commit_at, _siphon_replicated_at) AS metric_first_mentioned_in_commit_at,
            argMax(first_associated_with_milestone_at, _siphon_replicated_at) AS metric_first_associated_with_milestone_at,
            argMax(first_added_to_board_at, _siphon_replicated_at) AS metric_first_added_to_board_at,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_issue_metrics
          WHERE (traversal_path, issue_id) IN (SELECT traversal_path, id FROM base)
          GROUP BY ALL
          HAVING deleted = false
        ),
        siphon_issue_assignees_cte AS (SELECT
          traversal_path,
          issue_id,
          groupArray(toUInt64(user_id)) AS assignees
        FROM (
          SELECT
            traversal_path,
            issue_id,
            user_id,
            argMax(_siphon_deleted, _siphon_replicated_at) AS deleted
          FROM siphon_issue_assignees
          WHERE (traversal_path, issue_id) IN (SELECT traversal_path, id FROM base)
          GROUP BY ALL
          HAVING deleted = false
        )
        GROUP BY ALL
        ),
        siphon_label_links_cte AS (SELECT
          traversal_path,
          target_id AS issue_id,
          groupArray((toUInt64(label_id), created_at)) AS label_ids
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
          WHERE (traversal_path, target_type, target_id) IN (SELECT traversal_path, 'Issue' AS target_type, id AS target_id FROM base)
          GROUP BY ALL
          HAVING deleted = false
        )
        GROUP BY ALL
        ),
        siphon_award_emoji_cte AS (
          SELECT
            traversal_path,
            awardable_id AS issue_id,
            groupArray((name, toUInt64(user_id), created_at)) AS award_emojis
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
            WHERE (traversal_path, awardable_type, awardable_id) IN (SELECT traversal_path, 'Issue' AS awardable_type, id AS awardable_id FROM base)
            GROUP BY ALL
            HAVING deleted = false
          )
          GROUP BY ALL
        )
      SELECT
        base.id AS id,
        base.title AS title,
        base.author_id AS author_id,
        base.project_id AS project_id,
        base.created_at AS created_at,
        base.updated_at AS updated_at,
        base.description AS description,
        base.milestone_id AS milestone_id,
        base.iid AS iid,
        base.updated_by_id AS updated_by_id,
        base.weight AS weight,
        base.confidential AS confidential,
        base.due_date AS due_date,
        base.moved_to_id AS moved_to_id,
        base.time_estimate AS time_estimate,
        base.relative_position AS relative_position,
        base.service_desk_reply_to AS service_desk_reply_to,
        base.cached_markdown_version AS cached_markdown_version,
        base.last_edited_at AS last_edited_at,
        base.last_edited_by_id AS last_edited_by_id,
        base.discussion_locked AS discussion_locked,
        base.closed_at AS closed_at,
        base.closed_by_id AS closed_by_id,
        base.state_id AS state_id,
        base.duplicated_to_id AS duplicated_to_id,
        base.promoted_to_epic_id AS promoted_to_epic_id,
        base.health_status AS health_status,
        base.sprint_id AS sprint_id,
        base.blocking_issues_count AS blocking_issues_count,
        base.upvotes_count AS upvotes_count,
        base.work_item_type_id AS work_item_type_id,
        base.namespace_id AS namespace_id,
        base.start_date AS start_date,
        base.imported_from AS imported_from,
        base.namespace_traversal_ids AS namespace_traversal_ids,
        base.traversal_path AS traversal_path,
        base._siphon_replicated_at AS _siphon_replicated_at,
        base._siphon_deleted AS _siphon_deleted,
        siphon_issue_metrics_cte.metric_first_mentioned_in_commit_at AS metric_first_mentioned_in_commit_at,
        siphon_issue_metrics_cte.metric_first_associated_with_milestone_at AS metric_first_associated_with_milestone_at,
        siphon_issue_metrics_cte.metric_first_added_to_board_at AS metric_first_added_to_board_at,
        siphon_issue_assignees_cte.assignees AS assignees,
        siphon_label_links_cte.label_ids AS label_ids,
        siphon_award_emoji_cte.award_emojis AS award_emojis,
        siphon_work_item_current_statuses_cte.system_defined_status_id AS system_defined_status_id,
        siphon_work_item_current_statuses_cte.custom_status_id AS custom_status_id
      FROM base
      LEFT JOIN siphon_work_item_current_statuses_cte ON base.traversal_path = siphon_work_item_current_statuses_cte.traversal_path AND
base.id = siphon_work_item_current_statuses_cte.work_item_id

      LEFT JOIN siphon_issue_metrics_cte ON base.traversal_path = siphon_issue_metrics_cte.traversal_path AND
base.id = siphon_issue_metrics_cte.issue_id

      LEFT JOIN siphon_issue_assignees_cte ON base.traversal_path = siphon_issue_assignees_cte.traversal_path AND
base.id = siphon_issue_assignees_cte.issue_id

      LEFT JOIN siphon_label_links_cte ON base.traversal_path = siphon_label_links_cte.traversal_path AND
base.id = siphon_label_links_cte.issue_id

      LEFT JOIN siphon_award_emoji_cte ON base.traversal_path = siphon_award_emoji_cte.traversal_path AND
base.id = siphon_award_emoji_cte.issue_id

    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS work_items_mv'
  end
end
