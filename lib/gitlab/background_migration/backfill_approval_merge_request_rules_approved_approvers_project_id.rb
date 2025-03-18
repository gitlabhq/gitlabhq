# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalMergeRequestRulesApprovedApproversProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_merge_request_rules_approved_approvers_project_id
      feature_category :code_review_workflow
    end
  end
end
