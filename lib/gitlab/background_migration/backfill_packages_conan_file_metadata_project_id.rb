# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesConanFileMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_conan_file_metadata_project_id
      feature_category :package_registry
    end
  end
end
