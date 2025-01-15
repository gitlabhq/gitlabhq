# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPCiPipelinesTriggerId < Gitlab::BackgroundMigration::BatchedMigrationJob
      operation_name :backfill_p_ci_pipelines_trigger_id
      feature_category :continuous_integration

      def perform
        each_sub_batch do |sub_batch|
          correct_existing_trigger_id_for(sub_batch)
          backfill_trigger_id_from_commit_id(sub_batch)
        end
      end

      private

      def correct_existing_trigger_id_for(sub_batch)
        prev_incorrect_sub_query =
          sub_batch
            .select('p_ci_builds.commit_id AS pipeline_id, p_ci_builds.partition_id')
            .joins('INNER JOIN p_ci_builds ON p_ci_builds.id = ci_trigger_requests.commit_id')

        connection.execute(<<~SQL)
          UPDATE p_ci_pipelines
          SET trigger_id = (
            SELECT trigger_id
            FROM ci_trigger_requests
            WHERE commit_id = p_ci_pipelines.id
            LIMIT 1
          )
          FROM (#{prev_incorrect_sub_query.to_sql}) AS sub_trigger_query
          WHERE p_ci_pipelines.id = sub_trigger_query.pipeline_id
          AND p_ci_pipelines.partition_id = sub_trigger_query.partition_id
        SQL
      end

      def backfill_trigger_id_from_commit_id(sub_batch)
        sub_query =
          sub_batch
            .select('commit_id AS pipeline_id, trigger_id')
            .where.not(commit_id: nil)

        connection.execute(<<~SQL)
          UPDATE p_ci_pipelines
          SET trigger_id = sub_trigger_query.trigger_id
          FROM (#{sub_query.to_sql}) AS sub_trigger_query
          WHERE p_ci_pipelines.id = sub_trigger_query.pipeline_id
        SQL
      end
    end
  end
end
