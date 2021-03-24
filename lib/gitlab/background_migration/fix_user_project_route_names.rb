# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration fixes the routes.name for all user-projects that have names
    # that don't start with the users name.
    # For more info see https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/23272
    class FixUserProjectRouteNames
      def perform(from_id, to_id)
        ActiveRecord::Base.connection.execute <<~ROUTES_UPDATE
          WITH routes_to_update AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
            SELECT
                routes.id,
                users.name || ' / ' || projects.name AS correct_name
            FROM
                routes
                INNER JOIN projects ON routes.source_id = projects.id
                INNER JOIN namespaces ON projects.namespace_id = namespaces.id
                INNER JOIN users ON namespaces.owner_id = users.id
            WHERE
                routes.source_type = 'Project'
                AND routes.id BETWEEN #{from_id} AND #{to_id}
                AND namespaces.type IS NULL
                AND (routes.name NOT LIKE users.name || '%' OR routes.name IS NULL)
          )
          UPDATE
              routes
          SET
              name = routes_to_update.correct_name
          FROM
              routes_to_update
          WHERE
              routes_to_update.id = routes.id
        ROUTES_UPDATE
      end
    end
  end
end
