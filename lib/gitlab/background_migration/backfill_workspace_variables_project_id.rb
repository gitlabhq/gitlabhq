# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillWorkspaceVariablesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_workspace_variables_project_id
      feature_category :workspaces
    end
  end
end
