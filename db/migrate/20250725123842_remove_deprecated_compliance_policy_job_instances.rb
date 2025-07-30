# frozen_string_literal: true

class RemoveDeprecatedCompliancePolicyJobInstances < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  DEPRECATED_JOB_CLASSES = %w[Security::RefreshComplianceFrameworkSecurityPoliciesWorker]

  def up
    sidekiq_remove_jobs(job_klasses: DEPRECATED_JOB_CLASSES)
  end

  def down
    # This migration removes instances of a deprecated worker and cannot be undone.
  end
end
