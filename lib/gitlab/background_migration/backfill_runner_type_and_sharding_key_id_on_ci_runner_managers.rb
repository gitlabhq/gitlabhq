# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers < BatchedMigrationJob
      operation_name :backfill_runner_type_and_sharding_key_on_ci_runner_machines
      feature_category :runner

      UPDATE_RUNNER_MANAGERS_SQL = <<~SQL
        UPDATE ci_runner_machines
        SET
          sharding_key_id = ci_runners.sharding_key_id,
          runner_type = ci_runners.runner_type
        FROM ci_runners
        WHERE ci_runner_machines.runner_id = ci_runners.id
          AND ci_runner_machines.id IN (?);
      SQL

      class CiRunnerManager < ::Ci::ApplicationRecord
        self.table_name = 'ci_runner_machines'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch = sub_batch.where(sharding_key_id: nil).limit(sub_batch_size).select(:id)

          connection.exec_update(CiRunnerManager.sanitize_sql([UPDATE_RUNNER_MANAGERS_SQL, sub_batch]))
        end
      end
    end
  end
end
