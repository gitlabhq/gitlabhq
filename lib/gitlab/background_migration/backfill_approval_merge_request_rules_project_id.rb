# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillApprovalMergeRequestRulesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_merge_request_rules_project_id
      feature_category :code_review_workflow
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
