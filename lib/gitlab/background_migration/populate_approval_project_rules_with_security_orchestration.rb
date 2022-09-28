# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class doesn't delete merge request level rules
    # as this feature exists only in EE
    class PopulateApprovalProjectRulesWithSecurityOrchestration < BatchedMigrationJob
      def perform; end
    end
  end
end

# rubocop:disable Layout/LineLength
Gitlab::BackgroundMigration::PopulateApprovalProjectRulesWithSecurityOrchestration.prepend_mod_with('Gitlab::BackgroundMigration::PopulateApprovalProjectRulesWithSecurityOrchestration')
# rubocop:enable Layout/LineLength
