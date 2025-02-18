# frozen_string_literal: true

class AddProjectDesignManagementRoutesView < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    execute <<-SQL
      CREATE VIEW project_design_management_routes_view AS
        SELECT p.id,
               p.repository_storage as repository_storage,
               r.path as path_with_namespace,
               r.name as name_with_namespace
          FROM design_management_repositories dr
          JOIN projects p
            ON (dr.project_id = p.id)
          JOIN routes r
            ON (p.id = r.source_id AND source_type = 'Project')
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW project_design_management_routes_view;
    SQL
  end
end
