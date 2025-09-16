# frozen_string_literal: true

class FinalizeBackfillDastSiteValidationsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDastSiteValidationsProjectId',
      table_name: :dast_site_validations,
      column_name: :id,
      job_arguments: [:project_id, :dast_site_tokens, :project_id, :dast_site_token_id],
      finalize: true
    )
  end

  def down; end
end
