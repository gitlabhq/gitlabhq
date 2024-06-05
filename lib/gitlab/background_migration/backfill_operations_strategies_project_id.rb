# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOperationsStrategiesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_operations_strategies_project_id
      feature_category :feature_flags
    end
  end
end
