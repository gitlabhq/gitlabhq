# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This batched background migration is EE-only
    # Migration file: ee/lib/ee/gitlab/background_migration/backfill_subscription_user_add_on_assignment_versions.rb

    class BackfillSubscriptionUserAddOnAssignmentVersions < BatchedMigrationJob
      feature_category :value_stream_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillSubscriptionUserAddOnAssignmentVersions.prepend_mod
