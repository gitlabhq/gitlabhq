# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillApprovalsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approvals_project_id
      feature_category :code_review_workflow
    end
  end
end
