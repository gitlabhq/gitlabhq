# frozen_string_literal: true

class SwapMergeRequestMetricsIdToBigintForSelfHosts < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'merge_request_metrics'
  TMP_INDEX_NAME = 'tmp_index_mr_metrics_on_target_project_id_merged_at_nulls_last'
  INDEX_NAME = 'index_mr_metrics_on_target_project_id_merged_at_nulls_last'
  CONSTRAINT_NAME = 'merge_request_metrics_pkey'

  def up
    return if should_skip?
    return if temporary_column_already_dropped?
    return if columns_alredy_swapped?

    swap
  end

  def down
    return if should_skip?
    return if temporary_column_already_dropped?
    return unless columns_alredy_swapped?

    swap
  end

  private

  def swap
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true,
      name: 'index_merge_request_metrics_on_id_convert_to_bigint'
    add_concurrent_index TABLE_NAME, 'target_project_id, merged_at DESC NULLS LAST, id_convert_to_bigint DESC',
      name: TMP_INDEX_NAME

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id TO id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id_convert_to_bigint TO id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id_tmp TO id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger
        .on_table(TABLE_NAME, connection: connection)
        .name(:id, :id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      # Swap defaults of the columns, and change ownership of the sequence to the new id
      execute "ALTER SEQUENCE merge_request_metrics_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('merge_request_metrics_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      # Swap PK constraint
      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT IF EXISTS #{CONSTRAINT_NAME}"
      rename_index TABLE_NAME, 'index_merge_request_metrics_on_id_convert_to_bigint', CONSTRAINT_NAME
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT #{CONSTRAINT_NAME} PRIMARY KEY USING INDEX #{CONSTRAINT_NAME}"

      # Rename the rest of the indexes (we already hold an exclusive lock, so no need to use DROP INDEX CONCURRENTLY)
      execute "DROP INDEX IF EXISTS #{INDEX_NAME}"
      rename_index TABLE_NAME, TMP_INDEX_NAME, INDEX_NAME
    end
  end

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end

  def columns_alredy_swapped?
    table_columns = columns(TABLE_NAME)
    column_id = table_columns.find { |c| c.name == 'id' }
    column_id_convert_to_bigint = table_columns.find { |c| c.name == 'id_convert_to_bigint' }

    column_id.sql_type == 'bigint' && column_id_convert_to_bigint.sql_type == 'integer'
  end

  def temporary_column_already_dropped?
    table_columns = columns(TABLE_NAME)

    !table_columns.find { |c| c.name == 'id_convert_to_bigint' }
  end
end
