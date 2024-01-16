# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPartitionIdCiPipelineArtifact < BatchedMigrationJob
      operation_name :update_all
      feature_category :continuous_integration

      def perform
        return unless uses_multiple_partitions?

        each_sub_batch do |sub_batch|
          sub_batch
            .where('ci_pipeline_artifacts.pipeline_id = ci_pipelines.id')
            .update_all('partition_id = ci_pipelines.partition_id FROM ci_pipelines')
        end
      end

      private

      def uses_multiple_partitions?
        !!connection.select_value(<<~SQL)
          SELECT true FROM p_ci_builds WHERE partition_id = 101 LIMIT 1
        SQL
      end
    end
  end
end
