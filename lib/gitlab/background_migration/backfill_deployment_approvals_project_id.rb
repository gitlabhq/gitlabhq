# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Migration/BackgroundMigrationBaseClass -- BackfillDesiredShardingKeyJob inherits from BatchedMigrationJob.
    class BackfillDeploymentApprovalsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_deployment_approvals_project_id
      feature_category :continuous_delivery
    end
    # rubocop: enable Migration/BackgroundMigrationBaseClass
  end
end
