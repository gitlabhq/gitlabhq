# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillTriageCapabilitiesInSecurityInventoryFilters < BatchedMigrationJob
      feature_category :security_asset_inventories

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillTriageCapabilitiesInSecurityInventoryFilters.prepend_mod
