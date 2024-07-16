# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianProjectComponentsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_project_components_project_id
      feature_category :package_registry
    end
  end
end
