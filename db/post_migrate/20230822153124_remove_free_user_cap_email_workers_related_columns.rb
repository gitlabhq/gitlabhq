# frozen_string_literal: true

class RemoveFreeUserCapEmailWorkersRelatedColumns < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = 'namespace_details'
  OVER_LIMIT_CHECK_COLUMN_NAME = 'next_over_limit_check_at'
  OVER_LIMIT_CHECK_INDEX = 'index_next_over_limit_check_at_asc_order'
  OVER_LIMIT_NOTIFIED_AT_COLUMN_NAME = 'free_user_cap_over_limit_notified_at'
  OVER_LIMIT_NOTIFIED_AT_INDEX = 'index_fuc_over_limit_notified_at'

  def up
    remove_columns TABLE_NAME, OVER_LIMIT_CHECK_COLUMN_NAME, OVER_LIMIT_NOTIFIED_AT_COLUMN_NAME
  end

  def down
    unless column_exists?(TABLE_NAME, OVER_LIMIT_CHECK_COLUMN_NAME)
      add_column TABLE_NAME, OVER_LIMIT_CHECK_COLUMN_NAME, :datetime_with_timezone
    end

    unless column_exists?(TABLE_NAME, OVER_LIMIT_NOTIFIED_AT_COLUMN_NAME)
      add_column TABLE_NAME, OVER_LIMIT_NOTIFIED_AT_COLUMN_NAME, :datetime_with_timezone
    end

    add_concurrent_index TABLE_NAME, OVER_LIMIT_CHECK_COLUMN_NAME, name: OVER_LIMIT_CHECK_INDEX,
      order: { next_over_limit_check_at: 'ASC NULLS FIRST' }
    add_concurrent_index TABLE_NAME, OVER_LIMIT_NOTIFIED_AT_COLUMN_NAME, name: OVER_LIMIT_NOTIFIED_AT_INDEX
  end
end
