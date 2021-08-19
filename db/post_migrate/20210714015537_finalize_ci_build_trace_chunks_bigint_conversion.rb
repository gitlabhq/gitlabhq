# frozen_string_literal: true

class FinalizeCiBuildTraceChunksBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'ci_build_trace_chunks'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [['build_id'], ['build_id_convert_to_bigint']]
    )

    swap
  end

  def down
    swap
  end

  private

  def swap
    # This is to replace the existing "index_ci_build_trace_chunks_on_build_id_and_chunk_index" UNIQUE, btree (build_id, chunk_index)
    add_concurrent_index TABLE_NAME, [:build_id_convert_to_bigint, :chunk_index], unique: true, name: 'i_ci_build_trace_chunks_build_id_convert_to_bigint_chunk_index'

    # Add a foreign key on `build_id_convert_to_bigint` before we swap the columns and drop the old FK ()
    add_concurrent_foreign_key TABLE_NAME, :ci_builds, column: :build_id_convert_to_bigint, on_delete: :cascade, name: 'fk_rails_1013b761f2_tmp'

    with_lock_retries(raise_on_exhaustion: true) do
      # We'll need  ACCESS EXCLUSIVE lock on the related tables,
      # lets make sure it can be acquired from the start
      execute "LOCK TABLE #{TABLE_NAME}, ci_builds IN ACCESS EXCLUSIVE MODE"

      # Swap column names
      temp_name = 'build_id_tmp'
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:build_id)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(:build_id_convert_to_bigint)} TO #{quote_column_name(:build_id)}"
      execute "ALTER TABLE #{quote_table_name(TABLE_NAME)} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(:build_id_convert_to_bigint)}"

      # We need to update the trigger function in order to make PostgreSQL to
      # regenerate the execution plan for it. This is to avoid type mismatch errors like
      # "type of parameter 15 (bigint) does not match that when preparing the plan (integer)"
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name(:build_id, :build_id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults
      change_column_default TABLE_NAME, :build_id, nil
      change_column_default TABLE_NAME, :build_id_convert_to_bigint, 0

      # Rename the index on the `bigint` column to match the new column name
      # (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY here)
      execute 'DROP INDEX index_ci_build_trace_chunks_on_build_id_and_chunk_index'
      rename_index TABLE_NAME, 'i_ci_build_trace_chunks_build_id_convert_to_bigint_chunk_index', 'index_ci_build_trace_chunks_on_build_id_and_chunk_index'

      # Drop original FK on the old int4 `build_id` (fk_rails_1013b761f2)
      remove_foreign_key TABLE_NAME, name: 'fk_rails_1013b761f2'
      # We swapped the columns but the FK for buil_id is still using the temporary name for the build_id_convert_to_bigint column
      # So we have to also swap the FK name now that we dropped the other one with the same
      rename_constraint(TABLE_NAME, 'fk_rails_1013b761f2_tmp', 'fk_rails_1013b761f2')
    end
  end
end
