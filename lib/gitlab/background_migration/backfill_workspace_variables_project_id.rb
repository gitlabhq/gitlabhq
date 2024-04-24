# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillWorkspaceVariablesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_workspace_variables_project_id
      feature_category :remote_development
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
