# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestsClosingIssuesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_requests_closing_issues_project_id
      feature_category :code_review_workflow
    end
  end
end
