# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesDebianPublicationsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_debian_publications_project_id
      feature_category :package_registry
    end
  end
end
