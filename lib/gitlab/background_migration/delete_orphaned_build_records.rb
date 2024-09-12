# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedBuildRecords < BatchedMigrationJob
      operation_name :delete_orphaned_build_records
      feature_category :continuous_integration

      class CiPipeline < ::Ci::ApplicationRecord
        self.table_name = :p_ci_pipelines
        self.primary_key = :id
      end

      def perform
        distinct_each_batch do |batch|
          pipeline_ids = batch.pluck(batch_column)
          pipelines_query = CiPipeline
            .where('p_ci_builds.commit_id = p_ci_pipelines.id')
            .where('p_ci_builds.partition_id = p_ci_pipelines.partition_id')
            .select(1)

          base_relation
            .where(batch_column => pipeline_ids)
            .where('NOT EXISTS (?)', pipelines_query)
            .delete_all
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
