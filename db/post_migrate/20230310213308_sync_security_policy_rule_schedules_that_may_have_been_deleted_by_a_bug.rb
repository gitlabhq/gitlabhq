# frozen_string_literal: true

class SyncSecurityPolicyRuleSchedulesThatMayHaveBeenDeletedByABug < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class OrchestrationPolicyRuleSchedule < MigrationRecord
    self.table_name = 'security_orchestration_policy_rule_schedules'
  end

  def up
    return unless Gitlab.ee?
    return unless sync_scan_policies_worker

    OrchestrationPolicyRuleSchedule
      .select(:security_orchestration_policy_configuration_id)
      .distinct
      .where(policy_index: 1..)
      .pluck(:security_orchestration_policy_configuration_id)
      .map { |policy_configuration_id| [policy_configuration_id] }
      .then { |args_list| sync_scan_policies_worker.bulk_perform_async(args_list) }
  end

  def down
    # no-op
  end

  private

  def sync_scan_policies_worker
    unless defined?(@sync_scan_policies_worker)
      @sync_scan_policies_worker = 'Security::SyncScanPoliciesWorker'.safe_constantize
    end

    @sync_scan_policies_worker
  end
end
