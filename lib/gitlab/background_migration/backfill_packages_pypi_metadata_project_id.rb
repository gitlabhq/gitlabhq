# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesPypiMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_pypi_metadata_project_id
      feature_category :package_registry
    end
  end
end
