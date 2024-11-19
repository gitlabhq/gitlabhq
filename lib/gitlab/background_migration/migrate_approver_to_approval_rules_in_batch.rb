# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateApproverToApprovalRulesInBatch
      def perform(start_id, end_id); end
    end
  end
end

Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesInBatch.prepend_mod_with('Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesInBatch')
