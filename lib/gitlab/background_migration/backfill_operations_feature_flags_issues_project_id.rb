# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillOperationsFeatureFlagsIssuesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_operations_feature_flags_issues_project_id
      feature_category :feature_flags
    end
  end
end
