# frozen_string_literal: true

class FinalizeBackfillSecurityPolicies < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillSecurityPolicies"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :security_orchestration_policy_configurations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
