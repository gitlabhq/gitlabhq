# frozen_string_literal: true

class RemoveArtifactsArchiveIdForeignKeyFromProjectPagesMetadata < Gitlab::Database::Migration[1.0]
  CONSTRAINT_NAME = 'fk_69366a119e'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute('lock table ci_job_artifacts, project_pages_metadata in access exclusive mode')

      remove_foreign_key :project_pages_metadata, to_table: :ci_job_artifacts, column: :artifacts_archive_id, on_delete: :nullify, name: CONSTRAINT_NAME
    end
  end

  def down
    add_concurrent_foreign_key :project_pages_metadata, :ci_job_artifacts, column: :artifacts_archive_id, on_delete: :nullify, name: CONSTRAINT_NAME
  end
end
