# frozen_string_literal: true

class FinalizeBackfillRequirementsManagementTestReportsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillRequirementsManagementTestReportsProjectId',
      table_name: :requirements_management_test_reports,
      column_name: :id,
      job_arguments: [:project_id, :issues, :project_id, :issue_id],
      finalize: true
    )
  end

  def down; end
end
