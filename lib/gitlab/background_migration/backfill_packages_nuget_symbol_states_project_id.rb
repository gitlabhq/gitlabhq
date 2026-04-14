# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPackagesNugetSymbolStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_packages_nuget_symbol_states_project_id
      feature_category :geo_replication
    end
  end
end
