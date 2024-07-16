# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianGroupArchitecturesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_group_architectures_group_id
      feature_category :package_registry
    end
  end
end
