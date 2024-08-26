# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiJobVariablesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_job_variables_project_id
      feature_category :continuous_integration
    end
  end
end
