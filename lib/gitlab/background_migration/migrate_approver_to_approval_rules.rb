# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateApproverToApprovalRules
      # @param target_type [String] class of target, either 'MergeRequest' or 'Project'
      # @param target_id [Integer] id of target
      def perform(target_type, target_id, sync_code_owner_rule: true); end
    end
  end
end

Gitlab::BackgroundMigration::MigrateApproverToApprovalRules.prepend_mod_with('Gitlab::BackgroundMigration::MigrateApproverToApprovalRules')
