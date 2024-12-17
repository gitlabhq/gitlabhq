# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueMetricsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issue_metrics_namespace_id
      feature_category :value_stream_management
    end
  end
end
