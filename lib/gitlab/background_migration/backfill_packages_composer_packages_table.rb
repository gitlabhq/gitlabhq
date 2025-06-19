# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesComposerPackagesTable < BatchedMigrationJob
      operation_name :backfill_packages_composer_packages_table
      feature_category :package_registry

      COMPOSER_PACKAGE_TYPE = 6

      def perform
        each_sub_batch do |sub_batch|
          ApplicationRecord.connection.execute(
            <<~SQL.squish
              INSERT INTO packages_composer_packages (id, project_id, creator_id, created_at, updated_at, last_downloaded_at, status, name, version, target_sha, version_cache_sha, status_message, composer_json)

              #{sub_batch
                .where(package_type: COMPOSER_PACKAGE_TYPE)
                .joins('LEFT JOIN packages_composer_metadata ON packages_composer_metadata.package_id = packages_packages.id')
                .select("packages_packages.id,
                         packages_packages.project_id,
                         packages_packages.creator_id,
                         packages_packages.created_at,
                         packages_packages.updated_at,
                         packages_packages.last_downloaded_at,
                         packages_packages.status,
                         packages_packages.name,
                         packages_packages.version,
                         packages_composer_metadata.target_sha,
                         packages_composer_metadata.version_cache_sha,
                         packages_packages.status_message,
                         COALESCE(packages_composer_metadata.composer_json, '{}'::JSONB)")
                .to_sql}

              ON CONFLICT (id) DO NOTHING;
            SQL
          )
        end
      end
    end
  end
end
