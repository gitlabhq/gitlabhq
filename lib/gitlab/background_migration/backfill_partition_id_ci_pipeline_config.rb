# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPartitionIdCiPipelineConfig < BatchedMigrationJob
      operation_name :update_all
      feature_category :continuous_integration
      scope_to ->(relation) { relation.where('ci_pipelines_config.pipeline_id >= ?', first_pipeline_id) }

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('ci_pipelines_config.pipeline_id = ci_pipelines.id')
            .update_all('partition_id = ci_pipelines.partition_id FROM ci_pipelines')
        end
      end

      private

      def first_pipeline_id
        first_pipeline_with_partition_101 || max_pipeline_id
      end

      def first_pipeline_with_partition_101
        connection.select_value(<<~SQL)
          SELECT MIN(commit_id) FROM p_ci_builds WHERE partition_id = 101;
        SQL
      end

      def max_pipeline_id
        connection.select_value(<<~SQL)
          SELECT MAX(pipeline_id) FROM ci_pipelines_config;
        SQL
      end
    end
  end
end
