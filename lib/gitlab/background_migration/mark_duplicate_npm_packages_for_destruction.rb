# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # It seeks duplicate npm packages and mark them for destruction
    class MarkDuplicateNpmPackagesForDestruction < BatchedMigrationJob
      NPM_PACKAGE_TYPE = 2
      PENDING_DESTRUCTION_STATUS = 4

      operation_name :update_all
      feature_category :package_registry

      # Temporary class to link AR model to the `packages_packages` table
      class Package < ::ApplicationRecord
        include EachBatch

        self.table_name = 'packages_packages'
      end

      def perform
        distinct_each_batch do |batch|
          project_ids = batch.pluck(:project_id)

          subquery = Package
            .where(project_id: project_ids, package_type: NPM_PACKAGE_TYPE)
            .where.not(status: PENDING_DESTRUCTION_STATUS)
            .select('project_id, name, version, MAX(id) AS max_id')
            .group(:project_id, :name, :version)
            .having('COUNT(*) > 1')

          join_query = <<~SQL.squish
            INNER JOIN (#{subquery.to_sql}) AS duplicates
            ON packages_packages.project_id = duplicates.project_id
            AND packages_packages.name = duplicates.name
            AND packages_packages.version = duplicates.version
          SQL

          Package
            .joins(join_query)
            .where.not('packages_packages.id = duplicates.max_id')
            .each_batch do |batch_to_update|
            batch_to_update.update_all(status: PENDING_DESTRUCTION_STATUS)
          end
        end
      end
    end
  end
end
