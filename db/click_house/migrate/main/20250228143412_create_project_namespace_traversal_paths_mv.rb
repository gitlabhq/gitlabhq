# frozen_string_literal: true

class CreateProjectNamespaceTraversalPathsMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS project_namespace_traversal_paths_mv
      TO project_namespace_traversal_paths
      AS
      WITH cte AS (
        SELECT id, project_namespace_id FROM siphon_projects
      ), namespaces_cte AS (
        SELECT traversal_path, id, version, deleted
        FROM namespace_traversal_paths
        WHERE id IN (SELECT project_namespace_id FROM cte)
      )
      SELECT
        cte.id,
        namespaces_cte.traversal_path,
        namespaces_cte.version,
        namespaces_cte.deleted
      FROM cte
      INNER JOIN namespaces_cte ON namespaces_cte.id = cte.project_namespace_id
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS project_namespace_traversal_paths_mv
    SQL
  end
end
