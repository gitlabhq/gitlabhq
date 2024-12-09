# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSubscriptionAddOnPurchasesStartedAt < BatchedMigrationJob
      extend ActiveSupport::Concern

      operation_name :backfill_subscription_add_on_purchases_started_at
      scope_to ->(relation) { relation.where(started_at: nil) }
      feature_category :subscription_management

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all('started_at = created_at')
        end
      end
    end
  end
end
