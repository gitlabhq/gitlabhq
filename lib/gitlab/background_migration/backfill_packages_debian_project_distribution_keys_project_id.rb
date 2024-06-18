# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianProjectDistributionKeysProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_project_distribution_keys_project_id
      feature_category :package_registry
    end
  end
end
