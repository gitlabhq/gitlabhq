# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDependencyLinksProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_dependency_links_project_id
      feature_category :package_registry
    end
  end
end
