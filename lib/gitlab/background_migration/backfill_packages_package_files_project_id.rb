# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesPackageFilesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_package_files_project_id
      feature_category :package_registry
    end
  end
end
