# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSubscriptionUserAddOnAssignmentsOrganizationId < BackfillDesiredShardingKeyJob
      operation_name :backfill_subscription_user_add_on_assignments_organization_id
      feature_category :seat_cost_management
    end
  end
end
