# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillScanResultPoliciesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_scan_result_policies_project_id
      feature_category :security_policy_management
    end
  end
end
