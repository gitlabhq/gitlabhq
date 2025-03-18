# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillScanResultPoliciesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_scan_result_policies_namespace_id
      feature_category :security_policy_management
    end
  end
end
