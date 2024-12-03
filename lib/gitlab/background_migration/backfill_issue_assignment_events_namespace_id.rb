# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillIssueAssignmentEventsNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_issue_assignment_events_namespace_id
      feature_category :value_stream_management
    end
  end
end
