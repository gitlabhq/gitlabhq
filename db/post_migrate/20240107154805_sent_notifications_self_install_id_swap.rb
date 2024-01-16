# frozen_string_literal: true

class SentNotificationsSelfInstallIdSwap < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '16.8'

  disable_ddl_transaction!

  TABLE_NAME = :sent_notifications
  COLUMN_NAME = :id_convert_to_bigint
  INDEX_NAME = :index_sent_notifications_on_id_convert_to_bigint

  def up
    return if com_or_dev_or_test_but_not_jh?
    return if temp_column_removed?(TABLE_NAME, :id)
    return if columns_swapped?(TABLE_NAME, :id)

    swap
  end

  def down
    return if com_or_dev_or_test_but_not_jh?
    return if temp_column_removed?(TABLE_NAME, :id)
    return unless columns_swapped?(TABLE_NAME, :id)

    swap
  end

  def swap
    add_concurrent_index TABLE_NAME, COLUMN_NAME, unique: true, name: INDEX_NAME

    with_lock_retries(raise_on_exhaustion: true) do
      execute "LOCK TABLE #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE"

      # Swap Columns
      temp_name = quote_column_name(:id_tmp)
      id_name = quote_column_name(:id)
      id_convert_to_bigint_name = quote_column_name(COLUMN_NAME)
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_name} TO #{temp_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{id_convert_to_bigint_name} TO #{id_name}"
      execute "ALTER TABLE #{TABLE_NAME} RENAME COLUMN #{temp_name} TO #{id_convert_to_bigint_name}"

      # Reset trigger
      function_name = Gitlab::Database::UnidirectionalCopyTrigger.on_table(TABLE_NAME, connection: connection)
        .name(:id, :id_convert_to_bigint)
      execute "ALTER FUNCTION #{quote_table_name(function_name)} RESET ALL"

      execute "ALTER SEQUENCE #{TABLE_NAME}_id_seq OWNED BY #{TABLE_NAME}.id"
      change_column_default TABLE_NAME, :id, -> { "nextval('#{TABLE_NAME}_id_seq'::regclass)" }
      change_column_default TABLE_NAME, :id_convert_to_bigint, 0

      execute "ALTER TABLE #{TABLE_NAME} DROP CONSTRAINT #{TABLE_NAME}_pkey CASCADE"
      rename_index TABLE_NAME, INDEX_NAME, "#{TABLE_NAME}_pkey"
      execute "ALTER TABLE #{TABLE_NAME} ADD CONSTRAINT #{TABLE_NAME}_pkey PRIMARY KEY USING INDEX #{TABLE_NAME}_pkey"
    end
  end
end
