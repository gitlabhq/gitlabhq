# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MarkDuplicateMavenPackagesForDestruction < BatchedMigrationJob
      MAVEN_PACKAGE_TYPE = 1
      PENDING_DESTRUCTION_STATUS = 4

      operation_name :mark_duplicate_maven_package_for_destruction
      feature_category :package_registry

      class Package < ::ApplicationRecord
        include EachBatch

        self.table_name = 'packages_packages'
      end

      def perform
        distinct_each_batch do |batch|
          project_ids = batch.pluck(batch_column)

          subquery = Package
            .where(batch_column => project_ids, package_type: MAVEN_PACKAGE_TYPE)
            .where.not(status: PENDING_DESTRUCTION_STATUS)
            .select(:project_id, :name, :version, 'MAX(id) AS max_id')
            .group(:project_id, :name, :version)
            .having('COUNT(*) > 1')

          join_query = <<-SQL.squish
            INNER JOIN (#{subquery.to_sql}) AS duplicates
            ON packages_packages.project_id = duplicates.project_id
            AND packages_packages.name = duplicates.name
            AND COALESCE(packages_packages.version, '') = COALESCE(duplicates.version, '')
          SQL

          Package
            .joins(join_query)
            .where.not('packages_packages.id = duplicates.max_id')
            .each_batch { |b| b.update_all(status: PENDING_DESTRUCTION_STATUS) }
        end
      end
    end
  end
end
