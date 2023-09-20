# frozen_string_literal: true

class RestartSelfHostedSentNotificationsBigintConversion < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!

  TABLE = :sent_notifications
  COLUMNS = %i[id]

  def up
    return if should_skip? || id_is_bigint? || id_convert_to_bigint_exist?

    initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def down
    return if should_skip? || id_is_bigint?

    revert_initialize_conversion_of_integer_to_bigint(TABLE, COLUMNS)
  end

  def should_skip?
    com_or_dev_or_test_but_not_jh?
  end

  def id_is_bigint?
    table_columns = columns(TABLE)
    column_id = table_columns.find { |c| c.name == 'id' }
    column_id.sql_type == 'bigint'
  end

  def id_convert_to_bigint_exist?
    column_exists?(TABLE.to_s, 'id_convert_to_bigint')
  end
end
