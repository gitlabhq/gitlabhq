# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesBuildInfosProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_build_infos_project_id
      feature_category :package_registry
    end
  end
end
