# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillClusterAgentTokensProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_cluster_agent_tokens_project_id
      feature_category :deployment_management
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
