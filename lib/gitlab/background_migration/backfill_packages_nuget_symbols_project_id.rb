# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesNugetSymbolsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_nuget_symbols_project_id
      feature_category :package_registry
    end
  end
end
