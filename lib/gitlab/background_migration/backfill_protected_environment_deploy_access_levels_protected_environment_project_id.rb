# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProtectedEnvironmentDeployAccessLevelsProtectedEnvironmentProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_protected_environment_deploy_access_levels_protected_environment_project_id
      feature_category :continuous_delivery
    end
  end
end
