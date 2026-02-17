# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPlanLimitsPlanNameUid < BatchedMigrationJob
      operation_name :backfill_plan_limits_plan_name_uid
      feature_category :consumables_cost_management

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              UPDATE plan_limits
              SET plan_name_uid = plans.plan_name_uid
              FROM plans
              WHERE plan_limits.plan_id = plans.id
                AND plan_limits.id IN (#{sub_batch.select(:id).to_sql})
                AND plan_limits.plan_name_uid IS NULL
            SQL
          )
        end
      end
    end
  end
end
