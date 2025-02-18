# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestCleanupSchedulesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_cleanup_schedules_project_id
      feature_category :code_review_workflow
    end
  end
end
