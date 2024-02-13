# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDefaultOrganizationOwners < BatchedMigrationJob
      operation_name :backfill_default_organization_owners # This is used as the key on collecting metrics
      feature_category :cell

      def perform
        # no-op, replaced by BackfillDefaultOrganizationOwnersAgain
      end
    end
  end
end
