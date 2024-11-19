# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiTriggerRequestsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_trigger_requests_project_id
      feature_category :continuous_integration
    end
  end
end
