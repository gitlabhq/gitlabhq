# frozen_string_literal: true

class FinalizeHkBackfillSecurityFindingsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  TABLE_NAME = :security_findings
  BATCH_COLUMN = :id
  JOB_ARGS = %i[project_id vulnerability_scanners project_id scanner_id]

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillSecurityFindingsProjectId',
      table_name: TABLE_NAME,
      column_name: BATCH_COLUMN,
      job_arguments: [*JOB_ARGS],
      finalize: true
    )
  end

  def down; end
end
