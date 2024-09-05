# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiPipelineVariablesProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_p_ci_pipeline_variables_project_id
      feature_category :continuous_integration
    end
  end
end
