# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillShardingKeyIdOnCiRunners < BatchedMigrationJob
      operation_name :backfill_sharding_key_on_ci_runners
      scope_to ->(relation) { relation.where(runner_type: [2, 3]) }

      feature_category :runner

      UPDATE_GROUP_RUNNERS_SQL = <<~SQL
        UPDATE ci_runners
        SET sharding_key_id = ci_runner_namespaces.namespace_id
        FROM ci_runner_namespaces
        WHERE ci_runners.id = ci_runner_namespaces.runner_id
          AND ci_runners.id IN (?);
      SQL

      UPDATE_PROJECT_RUNNERS_SQL = <<~SQL
        UPDATE ci_runners
        SET sharding_key_id = (
          SELECT ci_runner_projects.project_id
          FROM ci_runner_projects
          WHERE ci_runner_projects.runner_id = ci_runners.id
          ORDER BY ci_runner_projects.id ASC
          LIMIT 1
        )
        FROM ci_runner_projects
        WHERE ci_runners.id = ci_runner_projects.runner_id
          AND ci_runners.id IN (?);
      SQL

      class CiRunner < ::Ci::ApplicationRecord
        self.table_name = 'ci_runners'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch = sub_batch.where(sharding_key_id: nil).limit(sub_batch_size).select(:id)

          connection.exec_update(CiRunner.sanitize_sql([UPDATE_GROUP_RUNNERS_SQL, sub_batch.where(runner_type: 2)]))
          connection.exec_update(CiRunner.sanitize_sql([UPDATE_PROJECT_RUNNERS_SQL, sub_batch.where(runner_type: 3)]))
        end
      end
    end
  end
end
