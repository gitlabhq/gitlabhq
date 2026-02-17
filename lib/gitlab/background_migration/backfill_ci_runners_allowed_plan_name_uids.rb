# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiRunnersAllowedPlanNameUids < BatchedMigrationJob
      operation_name :backfill_ci_runners_allowed_plan_name_uids
      feature_category :runner_core

      class Plan < ::ApplicationRecord
        self.table_name = 'plans'
      end

      def perform
        # Fetch plan_id -> plan_name_uid mapping from main database
        # This avoids cross-database JOIN issues between CI and main databases
        plan_mapping = Plan.connection.select_rows(
          "SELECT id, plan_name_uid FROM plans WHERE plan_name_uid IS NOT NULL"
        ).to_h

        return if plan_mapping.empty?

        # Build a VALUES list to use as a CTE, avoiding cross-database JOINs
        values_list = plan_mapping.map do |plan_id, plan_name_uid|
          "(#{connection.quote(plan_id)}, #{connection.quote(plan_name_uid)})"
        end.join(", ")

        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              WITH plan_map(plan_id, plan_name_uid) AS (
                VALUES #{values_list}
              )
              UPDATE ci_runners
              SET allowed_plan_name_uids = ARRAY(
                SELECT plan_map.plan_name_uid
                FROM unnest(ci_runners.allowed_plan_ids) WITH ORDINALITY AS t(plan_id, plan_id_index)
                JOIN plan_map ON plan_map.plan_id = t.plan_id
                ORDER BY t.plan_id_index
              )
              WHERE ci_runners.id IN (#{sub_batch.select(:id).to_sql})
                AND ci_runners.allowed_plan_ids != '{}'
            SQL
          )
        end
      end
    end
  end
end
