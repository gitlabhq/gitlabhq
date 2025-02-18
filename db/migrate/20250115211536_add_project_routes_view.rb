# frozen_string_literal: true

class AddProjectRoutesView < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    execute <<-SQL
      CREATE VIEW project_routes_view AS
        SELECT p.id,
               p.repository_storage AS repository_storage,
               r.path AS path_with_namespace,
               r.name AS name_with_namespace
        FROM projects p
        JOIN routes r
          ON (p.id = r.source_id AND source_type = 'Project');
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW project_routes_view;
    SQL
  end
end
