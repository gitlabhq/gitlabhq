# frozen_string_literal: true

class CreateNamespaceTraversalPathsMv < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW namespace_traversal_paths_mv
      TO namespace_traversal_paths
      AS
      SELECT
          id,
          if(length(traversal_ids) = 0,
             toString(ifNull(organization_id, 0)) || '/',
             toString(ifNull(organization_id, 0)) || '/' || arrayStringConcat(traversal_ids, '/') || '/') as traversal_path,
          _siphon_replicated_at AS version,
          _siphon_deleted AS deleted
      FROM siphon_namespaces;
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS namespace_traversal_paths_mv
    SQL
  end
end
