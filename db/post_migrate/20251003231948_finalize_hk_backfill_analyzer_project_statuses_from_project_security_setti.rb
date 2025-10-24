# frozen_string_literal: true

class FinalizeHkBackfillAnalyzerProjectStatusesFromProjectSecuritySetti < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillAnalyzerProjectStatusesFromProjectSecuritySettings',
      table_name: :project_security_settings,
      column_name: :project_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
