# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This batched background migration is EE-only,
    # see ee/lib/ee/gitlab/background_migration/backfill_duo_core_for_existing_subscription.rb for the actual
    # migration code.
    #
    # Creates Duo Core add-on purchase record for existing subscriptions with a paid or trial plans
    class BackfillDuoCoreForExistingSubscription < BatchedMigrationJob
      feature_category :'add-on_provisioning'

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillDuoCoreForExistingSubscription.prepend_mod
