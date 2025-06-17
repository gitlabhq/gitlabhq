# frozen_string_literal: true

module Ci
  module ProjectsWithVariablesQuery
    extend ActiveSupport::Concern

    class_methods do
      def projects_with_variables(project_ids, limit)
        project_ids_sql = <<~SQL.squish
          WITH input_projects AS (
            SELECT unnest(ARRAY[?]) AS project_id
          )
          SELECT input_projects.project_id
          FROM input_projects
          WHERE EXISTS (
            SELECT 1
            FROM #{quoted_table_name}
            WHERE #{quoted_table_name}.project_id = input_projects.project_id
          )
          LIMIT ?
        SQL

        connection.select_values(sanitize_sql_array([project_ids_sql, project_ids, limit]))
      end
    end
  end
end
