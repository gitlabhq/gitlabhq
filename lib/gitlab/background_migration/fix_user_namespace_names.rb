# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration fixes the namespaces.name for all user-namespaces that have names
    # that aren't equal to the users name.
    # Then it uses the updated names of the namespaces to update the associated routes
    # For more info see https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/23272
    class FixUserNamespaceNames
      def perform(from_id, to_id)
        fix_namespace_names(from_id, to_id)
        fix_namespace_route_names(from_id, to_id)
      end

      def fix_namespace_names(from_id, to_id)
        ActiveRecord::Base.connection.execute <<~UPDATE_NAMESPACES
          WITH namespaces_to_update AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
              SELECT
                  namespaces.id,
                  users.name AS correct_name
              FROM
                  namespaces
                  INNER JOIN users ON namespaces.owner_id = users.id
              WHERE
                  namespaces.type IS NULL
                  AND namespaces.id BETWEEN #{from_id} AND #{to_id}
                  AND namespaces.name != users.name
          )
          UPDATE
              namespaces
          SET
              name = correct_name
          FROM
              namespaces_to_update
          WHERE
              namespaces.id = namespaces_to_update.id
        UPDATE_NAMESPACES
      end

      def fix_namespace_route_names(from_id, to_id)
        ActiveRecord::Base.connection.execute <<~ROUTES_UPDATE
          WITH routes_to_update AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
              SELECT
                  routes.id,
                  users.name AS correct_name
              FROM
                  routes
                  INNER JOIN namespaces ON routes.source_id = namespaces.id
                  INNER JOIN users ON namespaces.owner_id = users.id
              WHERE
                  namespaces.type IS NULL
                  AND routes.source_type = 'Namespace'
                  AND namespaces.id BETWEEN #{from_id} AND #{to_id}
                  AND (routes.name != users.name OR routes.name IS NULL)
          )
          UPDATE
              routes
          SET
              name = correct_name
          FROM
              routes_to_update
          WHERE
              routes_to_update.id = routes.id
        ROUTES_UPDATE
      end
    end
  end
end
