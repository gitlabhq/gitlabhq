# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianGroupDistributionKeysGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_group_distribution_keys_group_id
      feature_category :package_registry
    end
  end
end
