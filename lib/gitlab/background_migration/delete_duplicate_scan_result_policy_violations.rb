# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes the older duplicate scan_result_policy_violations sharing the same
    # (approval_policy_rule_id, merge_request_id), keeping the newest row, so a
    # unique index can be added. See https://gitlab.com/gitlab-org/gitlab/-/issues/600966.
    class DeleteDuplicateScanResultPolicyViolations < BatchedMigrationJob
      cursor :id
      operation_name :delete_duplicate_scan_result_policy_violations
      feature_category :security_policy_management

      NEWER_DUPLICATE_EXISTS = <<~SQL
        EXISTS (
          SELECT 1
          FROM scan_result_policy_violations newer
          WHERE newer.approval_policy_rule_id = scan_result_policy_violations.approval_policy_rule_id
            AND newer.merge_request_id = scan_result_policy_violations.merge_request_id
            AND newer.id > scan_result_policy_violations.id
        )
      SQL

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where.not(approval_policy_rule_id: nil)
            .where(NEWER_DUPLICATE_EXISTS)
            .delete_all
        end
      end
    end
  end
end
