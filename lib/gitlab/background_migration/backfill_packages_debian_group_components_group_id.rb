# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianGroupComponentsGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_group_components_group_id
      feature_category :package_registry
    end
  end
end
