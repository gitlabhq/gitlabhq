# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedRoutes < BatchedMigrationJob
      operation_name :delete_orphaned_routes
      feature_category :groups_and_projects

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .joins('LEFT JOIN namespaces ON namespaces.id = routes.namespace_id')
            .where(namespaces: { id: nil })
            .delete_all
        end
      end
    end
  end
end
