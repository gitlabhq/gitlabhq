# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes orphaned packages_dependencies records that have no packages_dependency_links
    class DeleteOrphanedPackagesDependencies < BatchedMigrationJob
      operation_name :delete_all
      feature_category :package_registry

      scope_to ->(relation) {
                 relation.where(
                   <<~SQL.squish
                    NOT EXISTS (
                      SELECT 1
                      FROM packages_dependency_links
                      WHERE packages_dependency_links.dependency_id = packages_dependencies.id
                    )
                   SQL
                 )
               }

      def perform
        each_sub_batch(&:delete_all)
      end
    end
  end
end
