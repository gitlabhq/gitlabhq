# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAuditEventsStreamingHeadersGroupId < BackfillDesiredShardingKeyJob
      operation_name :backfill_audit_events_streaming_headers_group_id
      feature_category :audit_events
    end
  end
end
