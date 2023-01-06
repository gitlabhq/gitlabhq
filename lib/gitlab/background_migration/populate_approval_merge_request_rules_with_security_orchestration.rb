# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class doesn't delete merge request level rules
    # as this feature exists only in EE
    class PopulateApprovalMergeRequestRulesWithSecurityOrchestration < BatchedMigrationJob
      feature_category :database

      def perform; end
    end
  end
end

# rubocop:disable Layout/LineLength
Gitlab::BackgroundMigration::PopulateApprovalMergeRequestRulesWithSecurityOrchestration.prepend_mod_with('Gitlab::BackgroundMigration::PopulateApprovalMergeRequestRulesWithSecurityOrchestration')
# rubocop:enable Layout/LineLength
