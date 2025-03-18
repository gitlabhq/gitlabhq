# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianProjectComponentFilesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_project_component_files_project_id
      feature_category :package_registry
    end
  end
end
