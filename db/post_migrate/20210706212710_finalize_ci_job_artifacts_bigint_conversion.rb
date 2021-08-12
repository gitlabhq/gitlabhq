# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FinalizeCiJobArtifactsBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'ci_job_artifacts'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [%w[id job_id], %w[id_convert_to_bigint job_id_convert_to_bigint]]
    )

    swap
  end

  def down
    swap
  end

  private

  def swap
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name: 'index_ci_job_artifact_on_id_convert_to_bigint'
    # This is to replace the existing "index_ci_job_artifacts_for_terraform_reports" btree (project_id, id) where (file_type = 18)
    add_concurrent_index TABLE_NAME, [:project_id, :id_convert_to_bigint], name: 'index_ci_job_artifacts_for_terraform_reports_bigint', where: "file_type = 18"
    # This is to replace the existing "index_ci_job_artifacts_id_for_terraform_reports" btree (id) where (file_type = 18)
    add_concurrent_index TABLE_NAME, [:id_convert_to_bigint], name: 'index_ci_job_artifacts_id_for_terraform_reports_bigint', where: "file_type = 18"

    # Add a FK on `project_pages_metadata(artifacts_archive_id)` to `id_convert_to_bigint`, the old FK (fk_69366a119e)
    # will be removed when ci_job_artifacts_pkey constraint is droppped.
    fk_artifacts_archive_id = concurrent_foreign_key_name(:project_pages_metadata, :artifacts_archive_id)
    fk_artifacts_archive_id_tmp = "#{fk_artifacts_archive_id}_tmp"
    add_concurrent_foreign_key :project_pages_metadata, TABLE_NAME,
      column: :artifacts_archive_id, target_column: :id_convert_to_bigint,
      name: fk_artifacts_archive_id_tmp,
      on_delete: :nullify,
      reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start
      execute "LOCK TABLE #{TABLE_NAME}, project_pages_metadata IN ACCESS EXCLUSIVE MODE"

      # Swap column names
      temp_name = 'id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:id_convert_to_bigint)} TO #{quote_column_name(:id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name([:id, :job_id], [:id_convert_to_bigint, :job_id_convert_to_bigint])
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      execute "ALTER SEQUENCE ci_job_artifacts_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('ci_job_artifacts_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT ci_job_artifacts_pkey CASCADE" # this will drop ci_job_artifacts_pkey primary key
      rename_index TABLE_NAME, 'index_ci_job_artifact_on_id_convert_to_bigint', 'ci_job_artifacts_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT ci_job_artifacts_pkey PRIMARY KEY USING INDEX ci_job_artifacts_pkey"

      # Rename the rest of the indexes (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here
      execute 'DROP INDEX index_ci_job_artifacts_for_terraform_reports'
      rename_index TABLE_NAME, 'index_ci_job_artifacts_for_terraform_reports_bigint', 'index_ci_job_artifacts_for_terraform_reports'
      execute 'DROP INDEX index_ci_job_artifacts_id_for_terraform_reports'
      rename_index TABLE_NAME, 'index_ci_job_artifacts_id_for_terraform_reports_bigint', 'index_ci_job_artifacts_id_for_terraform_reports'

      # Change the name of the temporary FK for project_pages_metadata(artifacts_archive_id) -> id
      rename_constraint(:project_pages_metadata, fk_artifacts_archive_id_tmp, fk_artifacts_archive_id)
    end
  end
end
