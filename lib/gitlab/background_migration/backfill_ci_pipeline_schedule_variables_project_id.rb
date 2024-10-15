# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiPipelineScheduleVariablesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_pipeline_schedule_variables_project_id
      feature_category :continuous_integration
    end
  end
end
