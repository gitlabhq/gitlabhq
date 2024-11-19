# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- BackfillWorkItemHierarchyForEpics inherits from BatchedMigrationJob.
    class RequeueBackfillWorkItemHierarchyForEpics < BackfillWorkItemHierarchyForEpics
      operation_name :requeue_backfill_work_item_hierarchy_for_epics
      feature_category :team_planning
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
