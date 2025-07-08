# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillAnalyzerProjectStatusesFromProjectSecuritySettings < BatchedMigrationJob
      feature_category :security_asset_inventories
      operation_name :backfill_analyzer_project_statuses_from_project_security_settings

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::BackfillAnalyzerProjectStatusesFromProjectSecuritySettings.prepend_mod
