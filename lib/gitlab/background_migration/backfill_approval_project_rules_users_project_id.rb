# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillApprovalProjectRulesUsersProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_approval_project_rules_users_project_id
      feature_category :source_code_management
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
