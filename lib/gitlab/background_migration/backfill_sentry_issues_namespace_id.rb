# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSentryIssuesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_sentry_issues_namespace_id
      feature_category :observability
    end
  end
end
