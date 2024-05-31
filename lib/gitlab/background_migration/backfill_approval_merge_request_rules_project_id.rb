# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalMergeRequestRulesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_merge_request_rules_project_id
      feature_category :code_review_workflow
    end
  end
end
