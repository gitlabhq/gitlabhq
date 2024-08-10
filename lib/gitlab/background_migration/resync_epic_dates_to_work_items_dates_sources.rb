# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- BackfillEpicDatesToWorkItemDatesSources inherits from BatchedMigrationJob.
    class ResyncEpicDatesToWorkItemsDatesSources < BackfillEpicDatesToWorkItemDatesSources
      operation_name :resync_epic_dates_to_work_items_dates_sources
      feature_category :team_planning
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
