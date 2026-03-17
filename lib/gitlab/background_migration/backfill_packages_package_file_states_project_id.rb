# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesPackageFileStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_package_file_states_project_id
      feature_category :geo_replication
    end
  end
end
