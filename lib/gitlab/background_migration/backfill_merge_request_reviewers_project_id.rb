# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestReviewersProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_reviewers_project_id
      feature_category :code_review_workflow
    end
  end
end
