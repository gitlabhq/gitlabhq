# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUpstreamPipelinePartitionIdOnPCiBuilds < BatchedMigrationJob
      operation_name :update_all
      feature_category :continuous_integration

      def perform
        distinct_each_batch do |batch|
          pipeline_ids = batch.pluck(batch_column)
          base_relation
            .where(batch_column => pipeline_ids)
            .where('p_ci_builds.upstream_pipeline_id = ci_pipelines.id')
            .update_all('upstream_pipeline_partition_id = ci_pipelines.partition_id FROM ci_pipelines')
        end
      end

      private

      def base_relation
        define_batchable_model(batch_table, connection: connection, primary_key: :id)
          .where(batch_column => start_id..end_id)
      end
    end
  end
end
