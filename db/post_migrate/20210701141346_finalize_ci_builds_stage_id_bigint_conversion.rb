# frozen_string_literal: true

class FinalizeCiBuildsStageIdBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'ci_builds'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [%w[id stage_id], %w[id_convert_to_bigint stage_id_convert_to_bigint]]
    )

    swap_columns
  end

  def down
    swap_columns
  end

  private

  def swap_columns
    # Create a copy of the original column's index on the new column
    add_concurrent_index TABLE_NAME, :stage_id_convert_to_bigint, name: :index_ci_builds_on_converted_stage_id # rubocop:disable Migration/PreventIndexCreation

    # Create a copy of the original column's FK on the new column
    add_concurrent_foreign_key TABLE_NAME, :ci_stages, column: :stage_id_convert_to_bigint, on_delete: :cascade,
                                                       reverse_lock_order: true

    with_lock_retries(raise_on_exhaustion: true) do
      quoted_table_name = quote_table_name(TABLE_NAME)
      quoted_referenced_table_name = quote_table_name(:ci_stages)

      # Acquire locks up-front, not just to the build table but the FK's referenced table
      execute "LOCK TABLE #{quoted_referenced_table_name}, #{quoted_table_name} IN ACCESS EXCLUSIVE MODE"

      # Swap the column names of the two columns
      temporary_name = 'stage_id_tmp'
      execute "ALTER TABLE #{quoted_table_name} RENAME COLUMN #{quote_column_name(:stage_id)} TO #{quote_column_name(temporary_name)}"
      execute "ALTER TABLE #{quoted_table_name} RENAME COLUMN #{quote_column_name(:stage_id_convert_to_bigint)} TO #{quote_column_name(:stage_id)}"
      execute "ALTER TABLE #{quoted_table_name} RENAME COLUMN #{quote_column_name(temporary_name)} TO #{quote_column_name(:stage_id_convert_to_bigint)}"

      # Reset the function so PG drops the plan cache for the incorrect integer type
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection)
        .name([:id, :stage_id], [:id_convert_to_bigint, :stage_id_convert_to_bigint])
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Remove the original column index, and rename the new column index to the original name
      execute 'DROP INDEX index_ci_builds_on_stage_id'
      rename_index TABLE_NAME, :index_ci_builds_on_converted_stage_id, :index_ci_builds_on_stage_id

      # Remove the original column foreign key, and rename the new column foreign key to the original name
      remove_foreign_key TABLE_NAME, name: concurrent_foreign_key_name(TABLE_NAME, :stage_id)
      rename_constraint(
        TABLE_NAME,
        concurrent_foreign_key_name(TABLE_NAME, :stage_id_convert_to_bigint),
        concurrent_foreign_key_name(TABLE_NAME, :stage_id))
    end
  end
end
