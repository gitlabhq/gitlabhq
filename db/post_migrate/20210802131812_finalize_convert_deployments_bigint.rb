# frozen_string_literal: true

class FinalizeConvertDeploymentsBigint < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = 'deployments'
  COLUMN_NAME = 'deployable_id'
  COLUMN_NAME_BIGINT = "#{COLUMN_NAME}_convert_to_bigint"
  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
      table_name: TABLE_NAME,
      column_name: 'id',
      job_arguments: [[COLUMN_NAME], [COLUMN_NAME_BIGINT]]
    )

    swap
  end

  def down
    swap
  end

  def swap
    old_index_name = 'index_deployments_on_deployable_type_and_deployable_id'
    bigint_index_name = 'index_deployments_on_deployable_type_and_deployable_id_bigint'
    add_concurrent_index TABLE_NAME, ['deployable_type', COLUMN_NAME_BIGINT], name: bigint_index_name

    with_lock_retries(raise_on_exhaustion: true) do
      # Swap columns
      temp_name = "#{COLUMN_NAME}_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{quote_column_name(COLUMN_NAME)} TO #{quote_column_name(temp_name)}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{quote_column_name(COLUMN_NAME_BIGINT)} TO #{quote_column_name(COLUMN_NAME)}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{quote_column_name(temp_name)} TO #{quote_column_name(COLUMN_NAME_BIGINT)}"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME).name(COLUMN_NAME, COLUMN_NAME_BIGINT)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute "DROP INDEX #{old_index_name}"
      rename_index TABLE_NAME, bigint_index_name, old_index_name
    end
  end
end
