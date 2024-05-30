# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillAgentActivityEventsAgentProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_agent_activity_events_agent_project_id
      feature_category :deployment_management
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
