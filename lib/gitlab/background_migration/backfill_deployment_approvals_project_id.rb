# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDeploymentApprovalsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_deployment_approvals_project_id
      feature_category :continuous_delivery
    end
  end
end
