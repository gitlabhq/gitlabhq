# frozen_string_literal: true

class CreateEventsNewMv < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW events_new_mv
      TO events_new
      AS
      WITH cte AS (
      SELECT * FROM siphon_events
      ), group_lookups AS (
        SELECT id, traversal_path
        FROM namespace_traversal_paths
        WHERE id IN (SELECT DISTINCT group_id FROM cte)
      ), project_lookups AS (
        SELECT id, traversal_path
        FROM project_namespace_traversal_paths
        WHERE id IN (SELECT DISTINCT project_id FROM cte)
      )
      SELECT
          cte.id AS id,
          CASE
              WHEN cte.project_id != 0 THEN project_lookups.traversal_path
              WHEN cte.group_id != 0 THEN group_lookups.traversal_path
              ELSE '0/'
          END AS path,
          cte.author_id,
          cte.action AS action,
          cte.target_type AS target_type,
          cte.target_id AS target_id,
          cte.created_at,
          cte.updated_at,
          cte._siphon_replicated_at AS version,
          cte._siphon_deleted AS deleted
      FROM cte
      LEFT JOIN group_lookups ON group_lookups.id=cte.group_id
      LEFT JOIN project_lookups on project_lookups.id=cte.project_id
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS events_new_mv
    SQL
  end
end
