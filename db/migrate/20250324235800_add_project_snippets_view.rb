# frozen_string_literal: true

class AddProjectSnippetsView < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    execute <<-SQL
      CREATE VIEW project_snippets_routes_view AS
        SELECT sn.id,
               sh.name AS repository_storage,
               sr.disk_path,
               r.path AS path_with_namespace,
               r.name AS name_with_namespace
          FROM snippets sn
          JOIN snippet_repositories sr
            ON (sn.id=sr.snippet_id AND sn.type='ProjectSnippet')
          JOIN shards sh
            ON (sr.shard_id = sh.id)
          JOIN routes r
            ON (r.source_id = sn.project_id AND source_type = 'Project');
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW project_snippets_routes_view;
    SQL
  end
end
