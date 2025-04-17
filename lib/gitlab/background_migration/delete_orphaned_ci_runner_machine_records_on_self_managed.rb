# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedCiRunnerMachineRecordsOnSelfManaged < BatchedMigrationJob
      operation_name :delete_orphaned_ci_runner_machine_records
      feature_category :fleet_visibility

      class CiRunner < ::Ci::ApplicationRecord
        self.table_name = :ci_runners
        self.primary_key = :id
      end

      def perform
        distinct_each_batch do |batch|
          runner_ids = batch.pluck(batch_column)
          runner_query = CiRunner
            .where('ci_runner_machines.runner_id = ci_runners.id')
            .where('ci_runner_machines.runner_type = ci_runners.runner_type')
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
