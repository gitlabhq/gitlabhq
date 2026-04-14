# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the subscription_add_on_uid column in subscription_add_on_purchases
    # from the name (enum integer) column in subscription_add_ons.
    # This populates the fixed model ID so that add_on_purchases can reference
    # add-ons by a consistent identifier across all database instances.
    class BackfillSubscriptionAddOnPurchasesAddOnUid < BatchedMigrationJob
      operation_name :backfill_subscription_add_on_purchases_add_on_uid
      feature_category :plan_provisioning

      def perform
        each_sub_batch do |sub_batch|
          # Join subscription_add_on_purchases to subscription_add_ons via the
          # foreign key (subscription_add_on_id) and copy the add-on's name enum
          # integer into subscription_add_on_uid. Only update rows that haven't
          # been backfilled yet (where subscription_add_on_uid IS NULL).
          connection.execute(
            <<~SQL
              WITH sub_batch_ids AS MATERIALIZED (
                #{sub_batch.select(:id).limit(sub_batch_size).to_sql}
              )
              UPDATE subscription_add_on_purchases
              SET subscription_add_on_uid = subscription_add_ons.name
              FROM subscription_add_ons
              WHERE subscription_add_on_purchases.subscription_add_on_id = subscription_add_ons.id
                AND subscription_add_on_purchases.id IN (SELECT id FROM sub_batch_ids)
                AND subscription_add_on_purchases.subscription_add_on_uid IS NULL
            SQL
          )
        end
      end
    end
  end
end
