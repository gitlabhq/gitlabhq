# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestAssigneesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_assignees_project_id
      feature_category :code_review_workflow
    end
  end
end
