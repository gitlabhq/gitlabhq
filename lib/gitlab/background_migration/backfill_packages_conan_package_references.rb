# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesConanPackageReferences < BatchedMigrationJob
      operation_name :backfill_packages_conan_package_references
      scope_to ->(relation) {
        relation.where(package_reference_id: nil, conan_file_type: 2).where.not(conan_package_reference: nil)
      }
      feature_category :package_registry

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.connection.execute <<~SQL
            #{create_package_references(sub_batch)}
          SQL
          ApplicationRecord.connection.execute <<~SQL
            #{update_conan_file_metadata(sub_batch)}
          SQL
        end
      end

      private

      def create_package_references(relation)
        <<~SQL.squish
          INSERT INTO packages_conan_package_references (package_id, project_id, reference, created_at, updated_at)
          #{relation
             .joins('INNER JOIN packages_package_files ON packages_package_files.id = packages_conan_file_metadata.package_file_id')
             .select('packages_package_files.package_id AS package_id,
                      packages_package_files.project_id AS project_id,
                      decode(packages_conan_file_metadata.conan_package_reference, \'hex\') AS reference,
                      CURRENT_TIMESTAMP AS created_at,
                      CURRENT_TIMESTAMP AS updated_at')
             .to_sql}
          ON CONFLICT DO NOTHING;
        SQL
      end

      def update_conan_file_metadata(relation)
        <<~SQL.squish
          UPDATE packages_conan_file_metadata
          SET package_reference_id = packages_conan_package_references.id,
              updated_at = CURRENT_TIMESTAMP
          FROM (#{relation.to_sql}) batch
          INNER JOIN packages_package_files
            ON packages_package_files.id = batch.package_file_id
          INNER JOIN packages_conan_package_references
            ON packages_conan_package_references.package_id = packages_package_files.package_id
            AND packages_conan_package_references.project_id = packages_package_files.project_id
          WHERE packages_conan_file_metadata.id = batch.id
            AND packages_conan_package_references.reference = decode(batch.conan_package_reference, 'hex')
        SQL
      end
    end
  end
end
