# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiBuildPendingStatesProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_ci_build_pending_states_project_id
      feature_category :continuous_integration
    end
  end
end
