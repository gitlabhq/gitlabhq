# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDependenciesProjectId < BatchedMigrationJob
      operation_name :backfill_project_id
      feature_category :package_registry

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.connection.execute <<~SQL
            #{update_dependencies(sub_batch)}
            #{create_dependencies(sub_batch)}
            #{update_dependency_links(sub_batch)}
          SQL
        end
      end

      private

      def update_dependencies(relation)
        <<~SQL.squish
          UPDATE packages_dependencies
          SET project_id = subquery.project_id
          FROM
            (#{relation.select('DISTINCT ON (dependency_id) dependency_id, project_id').to_sql}) AS subquery
          WHERE packages_dependencies.id = subquery.dependency_id
            AND packages_dependencies.project_id IS NULL;
        SQL
      end

      def create_dependencies(relation)
        <<~SQL.squish
          INSERT INTO packages_dependencies (project_id, name, version_pattern)
          #{relation
             .joins('INNER JOIN packages_dependencies ON packages_dependencies.id = packages_dependency_links.dependency_id')
             .select('packages_dependency_links.project_id AS project_id,
                      packages_dependencies.name AS name,
                      packages_dependencies.version_pattern AS version_pattern')
             .where('packages_dependencies.project_id != packages_dependency_links.project_id')
             .to_sql}
          ON CONFLICT DO NOTHING;
        SQL
      end

      def update_dependency_links(relation)
        <<~SQL.squish
          UPDATE packages_dependency_links
          SET dependency_id = subquery.id
          FROM (
           SELECT packages_dependencies.id, joined.packages_dependency_link_id
           FROM
             (#{relation
                .joins('INNER JOIN packages_dependencies ON packages_dependencies.id = packages_dependency_links.dependency_id')
                .select('packages_dependency_links.id AS packages_dependency_link_id,
                         packages_dependency_links.project_id,
                         packages_dependencies.name,
                         packages_dependencies.version_pattern')
                .to_sql}) AS joined
             INNER JOIN packages_dependencies ON packages_dependencies.project_id = joined.project_id
             AND packages_dependencies.name = joined.name
             AND packages_dependencies.version_pattern = joined.version_pattern) AS subquery
          WHERE packages_dependency_links.id = subquery.packages_dependency_link_id;
        SQL
      end
    end
  end
end
