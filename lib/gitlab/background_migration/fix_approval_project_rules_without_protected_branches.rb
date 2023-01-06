# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class doesn't update approval project rules
    # as this feature exists only in EE
    class FixApprovalProjectRulesWithoutProtectedBranches < BatchedMigrationJob
      feature_category :database

      def perform; end
    end
  end
end

# rubocop:disable Layout/LineLength
Gitlab::BackgroundMigration::FixApprovalProjectRulesWithoutProtectedBranches.prepend_mod_with('Gitlab::BackgroundMigration::FixApprovalProjectRulesWithoutProtectedBranches')
# rubocop:enable Layout/LineLength
