# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillGitlabSubscriptionHistoriesHostedPlanNameUid < BatchedMigrationJob
      operation_name :backfill_gitlab_subscription_histories_hosted_plan_name_uid
      feature_category :subscription_management

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(
            <<~SQL
              UPDATE gitlab_subscription_histories
              SET hosted_plan_name_uid = plans.plan_name_uid
              FROM plans
              WHERE gitlab_subscription_histories.hosted_plan_id = plans.id
                AND gitlab_subscription_histories.id IN (#{sub_batch.select(:id).to_sql})
                AND gitlab_subscription_histories.hosted_plan_name_uid IS NULL
            SQL
          )
        end
      end
    end
  end
end
