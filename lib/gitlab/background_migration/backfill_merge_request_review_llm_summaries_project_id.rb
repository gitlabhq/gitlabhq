# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestReviewLlmSummariesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_review_llm_summaries_project_id
      feature_category :code_review_workflow
    end
  end
end
