# frozen_string_literal: true

class SwapCiBuildNeedsToBigIntForSelfHosts < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE_NAME = 'ci_build_needs'

  def up
    return if should_skip?
    return if temporary_column_already_dropped?
    return if columns_already_swapped?

    swap
  end

  def down
    return if should_skip?
    return if temporary_column_already_dropped?
    return unless columns_already_swapped?

    swap
  end

  private

  def swap
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name:
      'index_ci_build_needs_on_id_convert_to_bigint'

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id TO id_tmp"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id_convert_to_bigint TO id"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN id_tmp TO id_convert_to_bigint"

      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(
        TABLE_NAME, connection: Ci::ApplicationRecord.connection
      ).name(
        :id, :id_convert_to_bigint
      )

      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute "ALTER SEQUENCE ci_build_needs_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('ci_build_needs_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT ci_build_needs_pkey CASCADE"
      rename_index TABLE_NAME, 'index_ci_build_needs_on_id_convert_to_bigint', 'ci_build_needs_pkey'
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT ci_build_needs_pkey PRIMARY KEY USING INDEX ci_build_needs_pkey"
    end
  end

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end

  def columns_already_swapped?
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
