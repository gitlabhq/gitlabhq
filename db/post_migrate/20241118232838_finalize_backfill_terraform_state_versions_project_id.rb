# frozen_string_literal: true

class FinalizeBackfillTerraformStateVersionsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillTerraformStateVersionsProjectId',
      table_name: :terraform_state_versions,
      column_name: :id,
      job_arguments: [:project_id, :terraform_states, :project_id, :terraform_state_id],
      finalize: true
    )
  end

  def down; end
end
