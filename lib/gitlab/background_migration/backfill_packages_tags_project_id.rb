# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration populates the new `packages_tags.project_id` column from joining with `packages_packages` table
    class BackfillPackagesTagsProjectId < BatchedMigrationJob
      operation_name :update_all # This is used as the key on collecting metrics
      scope_to ->(relation) { relation.where(project_id: nil) }
      feature_category :package_registry

      def perform
        each_sub_batch do |sub_batch|
          joined = sub_batch
            .joins('INNER JOIN packages_packages ON packages_tags.package_id = packages_packages.id')
            .select('packages_tags.id, packages_packages.project_id')

          ApplicationRecord.connection.execute <<~SQL
            WITH joined_cte(packages_tag_id, project_id) AS MATERIALIZED (
              #{joined.to_sql}
            )
            UPDATE packages_tags
            SET project_id = joined_cte.project_id
            FROM joined_cte
            WHERE id = joined_cte.packages_tag_id
          SQL
        end
      end
    end
  end
end
