# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPushEventPayloadsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_push_event_payloads_project_id
      feature_category :source_code_management
    end
  end
end
