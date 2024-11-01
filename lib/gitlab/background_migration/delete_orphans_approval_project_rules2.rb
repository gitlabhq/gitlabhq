# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes orphans records whenever report_type equals to scan_finding (4) or license_scanning (2)
    # rubocop: disable CodeReuse/ActiveRecord
    class DeleteOrphansApprovalProjectRules2 < BatchedMigrationJob
      LICENSE_SCANNING_REPORT_TYPE = 2
      SCAN_FINDING_REPORT_TYPE = 4

      scope_to ->(relation) {
                 relation.where(report_type: [LICENSE_SCANNING_REPORT_TYPE, SCAN_FINDING_REPORT_TYPE],
                   security_orchestration_policy_configuration_id: nil)
               }

      operation_name :delete_all
      feature_category :database

      class ApprovalMergeRequestRuleSource < ::ApplicationRecord
        self.table_name = 'approval_merge_request_rule_sources'
      end

      def perform
        each_sub_batch do |sub_batch|
          ApprovalMergeRequestRuleSource
            .where(approval_project_rule_id: sub_batch.distinct.select(:id))
            .delete_all

          sub_batch.delete_all
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
