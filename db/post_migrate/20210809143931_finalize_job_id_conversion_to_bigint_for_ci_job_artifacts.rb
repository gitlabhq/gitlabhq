# frozen_string_literal: true

class FinalizeJobIdConversionToBigintForCiJobArtifacts < ActiveRecord::Migration[6.1]
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
    # This is to replace the existing "index_ci_job_artifacts_on_expire_at_and_job_id" btree (expire_at, job_id)
    add_concurrent_index TABLE_NAME, [:expire_at, :job_id_convert_to_bigint], name: 'index_ci_job_artifacts_on_expire_at_and_job_id_bigint'
    # This is to replace the existing "index_ci_job_artifacts_on_job_id_and_file_type" btree (job_id, file_type)
    add_concurrent_index TABLE_NAME, [:job_id_convert_to_bigint, :file_type], name: 'index_ci_job_artifacts_on_job_id_and_file_type_bigint', unique: true

    # # Add a FK on `job_id_convert_to_bigint` to `ci_builds(id)`, the old FK (fk_rails_c5137cb2c1)
    # # is removed below since it won't be dropped automatically.
    fk_ci_builds_job_id = concurrent_foreign_key_name(TABLE_NAME, :job_id, prefix: 'fk_rails_')
    fk_ci_builds_job_id_tmp = "#{fk_ci_builds_job_id}_tmp"

    add_concurrent_foreign_key TABLE_NAME, :ci_builds,
      column: :job_id_convert_to_bigint,
      name: fk_ci_builds_job_id_tmp,
      on_delete: :cascade,
      reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start

      execute "LOCK TABLE ci_builds, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      temp_name = 'job_id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:job_id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:job_id_convert_to_bigint)} TO #{quote_column_name(:job_id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:job_id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name([:id, :job_id], [:id_convert_to_bigint, :job_id_convert_to_bigint])
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      change_column_default TABLE_NAME, :job_id, nil
      change_column_default TABLE_NAME, :job_id_convert_to_bigint, 0

      # Rename the rest of the indexes (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here
      execute 'DROP INDEX index_ci_job_artifacts_on_expire_at_and_job_id'
      rename_index TABLE_NAME, 'index_ci_job_artifacts_on_expire_at_and_job_id_bigint', 'index_ci_job_artifacts_on_expire_at_and_job_id'
      execute 'DROP INDEX index_ci_job_artifacts_on_job_id_and_file_type'
      rename_index TABLE_NAME, 'index_ci_job_artifacts_on_job_id_and_file_type_bigint', 'index_ci_job_artifacts_on_job_id_and_file_type'

      # Drop original FK on the old int4 `job_id` (fk_rails_c5137cb2c1)
      remove_foreign_key TABLE_NAME, name: fk_ci_builds_job_id

      # We swapped the columns but the FK for job_id is still using the temporary name for the job_id_convert_to_bigint column
      # So we have to also swap the FK name now that we dropped the other one with the same
      rename_constraint(TABLE_NAME, fk_ci_builds_job_id_tmp, fk_ci_builds_job_id)
    end
  end
end
