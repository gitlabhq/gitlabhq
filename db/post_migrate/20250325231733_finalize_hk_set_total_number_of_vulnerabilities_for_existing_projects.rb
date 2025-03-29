# frozen_string_literal: true

class FinalizeHkSetTotalNumberOfVulnerabilitiesForExistingProjects < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'SetTotalNumberOfVulnerabilitiesForExistingProjects',
      table_name: :vulnerability_reads,
      column_name: :project_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
