# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestContextCommitsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_context_commits_project_id
      feature_category :code_review_workflow
    end
  end
end
