# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRemoteDevelopmentAgentConfigsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_remote_development_agent_configs_project_id
      feature_category :workspaces
    end
  end
end
