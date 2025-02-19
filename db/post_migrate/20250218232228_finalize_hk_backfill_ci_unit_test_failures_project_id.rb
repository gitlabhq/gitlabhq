# frozen_string_literal: true

class FinalizeHkBackfillCiUnitTestFailuresProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillCiUnitTestFailuresProjectId',
      table_name: :ci_unit_test_failures,
      column_name: :id,
      job_arguments: [:project_id, :ci_unit_tests, :project_id, :unit_test_id],
      finalize: true
    )
  end

  def down; end
end
