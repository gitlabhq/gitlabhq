# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAuditEventsStreamingEventTypeFiltersGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_audit_events_streaming_event_type_filters_group_id
      feature_category :audit_events
    end
  end
end
