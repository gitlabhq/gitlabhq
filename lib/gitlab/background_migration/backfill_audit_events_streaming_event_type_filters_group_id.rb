# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillAuditEventsStreamingEventTypeFiltersGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_audit_events_streaming_event_type_filters_group_id
      feature_category :audit_events
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
