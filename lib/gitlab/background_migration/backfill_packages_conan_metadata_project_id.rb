# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesConanMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_conan_metadata_project_id
      feature_category :package_registry
    end
  end
end
