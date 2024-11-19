# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- BackfillEpicIssuesIntoWorkItemParentLinks inherits from BatchedMigrationJob.
    class RequeueBackfillEpicIssuesIntoWorkItemParentLinks < BackfillEpicIssuesIntoWorkItemParentLinks
      operation_name :requeue_backfill_epic_issues_into_work_item_parent_links
      feature_category :team_planning
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
