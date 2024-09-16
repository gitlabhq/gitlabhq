# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiBuildNeedsProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_ci_build_needs_project_id
      feature_category :continuous_integration
    end
  end
end
