# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Fixes the `status` attribute of `security_scans` records
    class FixSecurityScanStatuses < BatchedMigrationJob
      feature_category :database

      def perform
        # no-op. The logic is defined in EE module.
      end
    end
  end
end

::Gitlab::BackgroundMigration::FixSecurityScanStatuses.prepend_mod
