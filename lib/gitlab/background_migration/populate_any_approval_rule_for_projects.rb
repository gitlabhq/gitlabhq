# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration creates any approver rule records according
    # to the given project IDs range. A _single_ INSERT is issued for the given range.
    class PopulateAnyApprovalRuleForProjects
      def perform(from_id, to_id)
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForProjects.prepend_if_ee('EE::Gitlab::BackgroundMigration::PopulateAnyApprovalRuleForProjects')
