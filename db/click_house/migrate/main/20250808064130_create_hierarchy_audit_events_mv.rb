# frozen_string_literal: true

class CreateHierarchyAuditEventsMv < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS hierarchy_audit_events_mv TO hierarchy_audit_events AS
      WITH cte AS
        (
            SELECT *
            FROM siphon_group_audit_events
        ),
        namespace_paths AS
        (
            SELECT * FROM (
              SELECT
                  id,
                  argMax(traversal_path, version) AS traversal_path,
                  argMax(deleted, version) AS deleted
              FROM namespace_traversal_paths
              WHERE id IN (
                  SELECT DISTINCT group_id
                  FROM cte
              )
              GROUP BY id
            ) WHERE deleted = false
        )
        SELECT
          multiIf(namespace_paths.traversal_path != '', namespace_paths.traversal_path, '0/') AS traversal_path,
          cte.id AS id,
          cte.group_id AS group_id,
          cte.author_id AS author_id,
          cte.target_id AS target_id,
          cte.event_name AS event_name,
          cte.details AS details,
          cte.ip_address AS ip_address,
          cte.author_name AS author_name,
          cte.entity_path AS entity_path,
          cte.target_details AS target_details,
          cte.target_type AS target_type,
          cte.created_at AS created_at,
          cte._siphon_replicated_at AS version,
          cte._siphon_deleted AS deleted
        FROM cte
        LEFT JOIN namespace_paths ON namespace_paths.id = cte.group_id
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS hierarchy_audit_events_mv'
  end
end
