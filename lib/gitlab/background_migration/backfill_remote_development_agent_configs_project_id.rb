# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillRemoteDevelopmentAgentConfigsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_remote_development_agent_configs_project_id
      feature_category :remote_development
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
