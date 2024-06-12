# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOperationsStrategiesUserListsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_operations_strategies_user_lists_project_id
      feature_category :feature_flags
    end
  end
end
