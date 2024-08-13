# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillComplianceFrameworkSecurityPoliciesNamespaceId < BackfillDesiredShardingKeyJob
      operation_name :backfill_compliance_framework_security_policies_namespace_id
      feature_category :security_policy_management
    end
  end
end
