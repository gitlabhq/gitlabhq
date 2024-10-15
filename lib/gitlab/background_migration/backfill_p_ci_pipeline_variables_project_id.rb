# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiPipelineVariablesProjectId < BackfillDesiredShardingKeyPartitionJob
      operation_name :backfill_p_ci_pipeline_variables_project_id
      feature_category :continuous_integration

      scope_to ->(relation) { relation }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.connection.execute(construct_query(sub_batch: sub_batch))
        end
      end
    end
  end
end
