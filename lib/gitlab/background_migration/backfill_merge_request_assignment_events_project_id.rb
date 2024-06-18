# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillMergeRequestAssignmentEventsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_merge_request_assignment_events_project_id
      feature_category :value_stream_management
    end
  end
end
