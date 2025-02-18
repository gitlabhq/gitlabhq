# frozen_string_literal: true

class FinalizeBackfillComplianceViolationNullTargetProjectIdsMigration < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillComplianceViolationNullTargetProjectIds',
      table_name: :merge_requests_compliance_violations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
