# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillSdSecurityScanProfilesTriggers < BatchedMigrationJob
      feature_category :security_asset_inventories

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillSdSecurityScanProfilesTriggers.prepend_mod
