# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianProjectArchitecturesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_project_architectures_project_id
      feature_category :package_registry
    end
  end
end
