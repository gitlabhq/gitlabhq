# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BatchedMigrationBaseClass -- rerun existing migration
    class RerunEpicDatesToWorkItemDatesSourcesSync < BackfillEpicDatesToWorkItemDatesSources
      operation_name :rerun_epic_dates_to_work_item_dates_sources_sync
      feature_category :team_planning
    end
    # rubocop: enable Migration/BatchedMigrationBaseClass
  end
end
