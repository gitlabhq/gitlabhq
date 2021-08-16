# frozen_string_literal: true

class FinalizeCiSourcesPipelinesBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'ci_sources_pipelines'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [['source_job_id'], ['source_job_id_convert_to_bigint']]
    )

    swap
  end

  def down
    swap
  end

  private

  def swap
    # This is to replace the existing "index_ci_sources_pipelines_on_source_job_id" btree (source_job_id)
    add_concurrent_index TABLE_NAME, :source_job_id_convert_to_bigint, name: 'index_ci_sources_pipelines_on_source_job_id_convert_to_bigint'

    # Add a foreign key on `source_job_id_convert_to_bigint` before we swap the columns and drop the old FK (fk_be5624bf37)
    add_concurrent_foreign_key TABLE_NAME, :ci_builds,
      column: :source_job_id_convert_to_bigint, on_delete: :cascade,
      name: 'fk_be5624bf37_tmp', reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start
      execute "LOCK TABLE ci_builds, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Swap column names
      temp_name = 'source_job_id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:source_job_id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:source_job_id_convert_to_bigint)} TO #{quote_column_name(:source_job_id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:source_job_id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name(:source_job_id, :source_job_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # No need to swap defaults, both columns have no default value

      # Rename the index on the `bigint` column to match the new column name
      # (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here)
      execute 'DROP INDEX index_ci_sources_pipelines_on_source_job_id'
      rename_index TABLE_NAME, 'index_ci_sources_pipelines_on_source_job_id_convert_to_bigint', 'index_ci_sources_pipelines_on_source_job_id'

      # Drop original FK on the old int4 `source_job_id` (fk_be5624bf37)
      remove_foreign_key TABLE_NAME, name: 'fk_be5624bf37'
      # We swapped the columns but the FK is still using the temporary name
      # So we have to also swap the FK name now that we dropped the other one
      rename_constraint(TABLE_NAME, 'fk_be5624bf37_tmp', 'fk_be5624bf37')
    end
  end
end
