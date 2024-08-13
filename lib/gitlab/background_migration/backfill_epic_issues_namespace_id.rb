# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillEpicIssuesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_epic_issues_namespace_id
      feature_category :portfolio_management
    end
  end
end
