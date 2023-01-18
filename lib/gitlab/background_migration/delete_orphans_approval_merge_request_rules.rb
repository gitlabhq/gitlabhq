# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes orphans records whenever report_type equals to scan_finding (i.e., 4)
    class DeleteOrphansApprovalMergeRequestRules < BatchedMigrationJob
      scope_to ->(relation) { relation.where(report_type: 4) }

      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(security_orchestration_policy_configuration_id: nil).delete_all
        end
      end
    end
  end
end
