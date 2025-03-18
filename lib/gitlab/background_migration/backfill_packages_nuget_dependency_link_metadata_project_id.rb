# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesNugetDependencyLinkMetadataProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_nuget_dependency_link_metadata_project_id
      feature_category :package_registry
    end
  end
end
