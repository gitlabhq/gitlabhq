# frozen_string_literal: true

class FinalizeCleanupRepositoryLanguagesLanguageId < Gitlab::Database::Migration[2.4]
  milestone '19.6'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CleanupRepositoryLanguagesLanguageId',
      table_name: :repository_languages,
      column_name: :project_id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op - finalization migrations are irreversible
  end
end
