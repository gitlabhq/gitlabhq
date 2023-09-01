# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Background migration to sync scan result policies from YAML to DB table by kicking off sync Sidekiq jobs
    class SyncScanResultPolicies < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::SyncScanResultPolicies.prepend_mod
