# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesPackageFileBuildInfosProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_package_file_build_infos_project_id
      feature_category :package_registry
    end
  end
end
