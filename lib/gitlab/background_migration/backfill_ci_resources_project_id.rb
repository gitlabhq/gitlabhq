# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiResourcesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_resources_project_id
      feature_category :continuous_integration
    end
  end
end
