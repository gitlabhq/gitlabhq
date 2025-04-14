# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianFileMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_file_metadata_project_id
      feature_category :package_registry
    end
  end
end
