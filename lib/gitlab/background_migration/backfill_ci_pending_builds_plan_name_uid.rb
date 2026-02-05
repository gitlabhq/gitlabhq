# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiPendingBuildsPlanNameUid < BatchedMigrationJob
      operation_name :backfill_ci_pending_builds_plan_name_uid
      feature_category :continuous_integration

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
              UPDATE ci_pending_builds
              SET plan_name_uid = plan_map.plan_name_uid
              FROM plan_map
              WHERE ci_pending_builds.plan_id = plan_map.plan_id
                AND ci_pending_builds.id IN (#{sub_batch.select(:id).to_sql})
                AND ci_pending_builds.plan_name_uid IS NULL
                AND ci_pending_builds.plan_id IS NOT NULL
            SQL
          )
        end
      end
    end
  end
end
