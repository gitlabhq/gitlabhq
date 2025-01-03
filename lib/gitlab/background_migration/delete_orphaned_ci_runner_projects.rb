# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedCiRunnerProjects < BatchedMigrationJob
      operation_name :delete_orphaned_ci_runner_projects
      feature_category :runner

      class CiRunner < ::Ci::ApplicationRecord
        self.table_name = :ci_runners
        self.primary_key = :id
      end

      def perform
        distinct_each_batch do |batch|
          runner_ids = batch.pluck(batch_column)
          runner_query = CiRunner
            .where('ci_runner_projects.runner_id = ci_runners.id')
            .select(1)

          base_relation
            .where(batch_column => runner_ids)
            .where('NOT EXISTS (?)', runner_query)
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
