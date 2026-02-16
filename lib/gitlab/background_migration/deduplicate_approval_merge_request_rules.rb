# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeduplicateApprovalMergeRequestRules < BatchedMigrationJob
      feature_category :security_policy_management

      def perform; end
    end
  end
end

Gitlab::BackgroundMigration::DeduplicateApprovalMergeRequestRules.prepend_mod
