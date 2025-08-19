# frozen_string_literal: true

class ReAddWorkItemHierarchyMv < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS hierarchy_work_items_mv TO hierarchy_work_items
      AS WITH
          cte AS
          (
              SELECT *
              FROM siphon_issues
          ),
          namespace_paths AS
          (
              -- look up `traversal_path` values
              SELECT * FROM (
                SELECT
                    id,
                    argMax(traversal_path, version) AS traversal_path,
                    argMax(deleted, version) AS deleted
                FROM namespace_traversal_paths
                WHERE id IN (
                    SELECT DISTINCT namespace_id
                    FROM cte
                )
                GROUP BY id
              ) WHERE deleted = false
          ),
          collected_label_ids AS
          (
            SELECT work_item_id, concat('/', arrayStringConcat(arraySort(groupArray(label_id)), '/'), '/') AS label_ids
            FROM (
              SELECT
                work_item_id,
                label_id,
                id,
                argMax(deleted, version) AS deleted
              FROM work_item_label_links
              WHERE work_item_id IN (SELECT id FROM cte)
              GROUP BY work_item_id, label_id, id
            ) WHERE deleted = false
            GROUP BY work_item_id
          ),
          collected_assignee_ids AS
          (
            SELECT issue_id, concat('/', arrayStringConcat(arraySort(groupArray(user_id)), '/'), '/') AS user_ids
            FROM (
              SELECT
                issue_id,
                user_id,
                argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
              FROM siphon_issue_assignees
              WHERE issue_id IN (SELECT id FROM cte)
              GROUP BY issue_id, user_id
            ) WHERE _siphon_deleted = false
            GROUP BY issue_id
          ),
          collected_custom_status_records AS
          (
            SELECT work_item_id, max(system_defined_status_id) AS system_defined_status_id, max(custom_status_id) AS custom_status_id
            FROM (
              SELECT
                work_item_id,
                id,
                argMax(system_defined_status_id, _siphon_replicated_at) AS system_defined_status_id,
                argMax(custom_status_id, _siphon_replicated_at) AS custom_status_id,
                argMax(_siphon_deleted, _siphon_replicated_at) AS _siphon_deleted
              FROM siphon_work_item_current_statuses
              GROUP BY work_item_id, id
            ) WHERE _siphon_deleted = false
            GROUP BY work_item_id
          ),
          finalized AS
          (
            SELECT
                -- handle the case where namespace_id is null
                multiIf(cte.namespace_id != 0, namespace_paths.traversal_path, '0/') AS traversal_path,
                cte.id AS id,
                cte.title AS title,
                cte.author_id AS author_id,
                cte.created_at AS created_at,
                cte.updated_at AS updated_at,
                cte.milestone_id AS milestone_id,
                cte.iid AS iid,
                cte.updated_by_id AS updated_by_id,
                cte.weight AS weight,
                cte.confidential AS confidential,
                cte.due_date AS due_date,
                cte.moved_to_id AS moved_to_id,
                cte.time_estimate AS time_estimate,
                cte.relative_position AS relative_position,
                cte.last_edited_at AS last_edited_at,
                cte.last_edited_by_id AS last_edited_by_id,
                cte.closed_at AS closed_at,
                cte.closed_by_id AS closed_by_id,
                cte.state_id AS state_id,
                cte.duplicated_to_id AS duplicated_to_id,
                cte.promoted_to_epic_id AS promoted_to_epic_id,
                cte.health_status AS health_status,
                cte.sprint_id AS sprint_id,
                cte.blocking_issues_count AS blocking_issues_count,
                cte.upvotes_count AS upvotes_count,
                cte.work_item_type_id AS work_item_type_id,
                cte.namespace_id AS namespace_id,
                cte.start_date AS start_date,
                collected_label_ids.label_ids AS label_ids,
                collected_assignee_ids.user_ids AS assignee_ids,
                collected_custom_status_records.custom_status_id AS custom_status_id,
                collected_custom_status_records.system_defined_status_id AS system_defined_status_id,
                cte._siphon_replicated_at AS version,
                cte._siphon_deleted AS deleted
            FROM cte
            LEFT JOIN namespace_paths ON namespace_paths.id = cte.namespace_id
            LEFT JOIN collected_assignee_ids ON collected_assignee_ids.issue_id = cte.id
            LEFT JOIN collected_label_ids ON collected_label_ids.work_item_id = cte.id
            LEFT JOIN collected_custom_status_records ON collected_custom_status_records.work_item_id = cte.id
          )
          SELECT * FROM finalized
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS hierarchy_work_items_mv
    SQL
  end
end
