# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes orphans records whenever report_type equals to scan_finding (i.e., 4)
    class DeleteOrphansApprovalProjectRules < BatchedMigrationJob
      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(report_type: 4, security_orchestration_policy_configuration_id: nil).delete_all
        end
      end
    end
  end
end
