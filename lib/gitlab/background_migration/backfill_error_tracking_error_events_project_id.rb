# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillErrorTrackingErrorEventsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_error_tracking_error_events_project_id
      feature_category :observability
    end
  end
end
