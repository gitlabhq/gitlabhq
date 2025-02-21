# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianGroupComponentFilesGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_group_component_files_group_id
      feature_category :package_registry
    end
  end
end
