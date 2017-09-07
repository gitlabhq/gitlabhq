module Gitlab
  module BackgroundMigration
    class DeleteConflictingRedirectRoutes
      class Route < ActiveRecord::Base
        self.table_name = 'routes'
      end

      class RedirectRoute < ActiveRecord::Base
        self.table_name = 'redirect_routes'
      end

      # start_id - The start ID of the range of events to process
      # end_id - The end ID of the range to process.
      def perform(start_id, end_id)
        return unless migrate?

        conflicts = RedirectRoute.where(routes_match_redirects_clause(start_id, end_id))
        num_rows = conflicts.delete_all

        Rails.logger.info("Gitlab::BackgroundMigration::DeleteConflictingRedirectRoutes [#{start_id}, #{end_id}] - Deleted #{num_rows} redirect routes that were conflicting with routes.")
      end

      def migrate?
        Route.table_exists? && RedirectRoute.table_exists?
      end

      def routes_match_redirects_clause(start_id, end_id)
        <<~ROUTES_MATCH_REDIRECTS
          EXISTS (
            SELECT 1 FROM routes
            WHERE (#{route_paths_match_redirects})
            AND routes.id BETWEEN #{start_id} AND #{end_id}
          )
        ROUTES_MATCH_REDIRECTS
      end

      def route_paths_match_redirects
        if Gitlab::Database.postgresql?
          <<~ROUTE_PATHS_MATCH_REDIRECTS
            LOWER(redirect_routes.path) = LOWER(routes.path)
            OR LOWER(redirect_routes.path) LIKE LOWER(CONCAT(routes.path, '/%'))
          ROUTE_PATHS_MATCH_REDIRECTS
        else
          <<~ROUTE_PATHS_MATCH_REDIRECTS
            redirect_routes.path = routes.path
            OR redirect_routes.path LIKE CONCAT(routes.path, '/%')
          ROUTE_PATHS_MATCH_REDIRECTS
        end
      end
    end
  end
end
