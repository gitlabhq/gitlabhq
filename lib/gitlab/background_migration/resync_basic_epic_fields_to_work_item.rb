# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- BackfillEpicBasicFieldsToWorkItemRecord inherits from BatchedMigrationJob.
    class ResyncBasicEpicFieldsToWorkItem < BackfillEpicBasicFieldsToWorkItemRecord
      operation_name :resync_basic_epic_fields_to_work_item
      feature_category :team_planning
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
