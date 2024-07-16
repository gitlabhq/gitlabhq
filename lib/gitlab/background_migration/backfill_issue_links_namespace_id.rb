# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueLinksNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issue_links_namespace_id
      feature_category :team_planning
    end
  end
end
