# frozen_string_literal: true

class SwapColumnsCiBuildNeedsBigIntConversion < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = 'ci_build_needs'

  def up
    return unless should_run?

    swap
  end

  def down
    return unless should_run?

    swap
  end

  private

  def should_run?
    !Gitlab.jh? && (Gitlab.com? || Gitlab.dev_or_test_env?)
  end

  def swap
    add_concurrent_index TABLE_NAME, :id_convert_to_bigint, unique: true, name:
      'index_ci_build_needs_on_id_convert_to_bigint'

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      id_name = quote_column_name(:id)
      temp_name = quote_column_name('id_tmp')
      id_convert_to_bigint_name = quote_column_name(:id_convert_to_bigint)

      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_name} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_convert_to_bigint_name} TO #{id_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{id_convert_to_bigint_name}"

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
end
