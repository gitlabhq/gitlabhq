# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDastPreScanVerificationsProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_dast_pre_scan_verifications_project_id
      feature_category :dynamic_application_security_testing
    end
  end
end
