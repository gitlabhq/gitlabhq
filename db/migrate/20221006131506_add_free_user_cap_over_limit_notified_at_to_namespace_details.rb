# frozen_string_literal: true

class AddFreeUserCapOverLimitNotifiedAtToNamespaceDetails < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TABLE_NAME = 'namespace_details'
  COLUMN_NAME = 'free_user_cap_over_limit_notified_at'

  def up
    with_lock_retries do
      add_column(TABLE_NAME, COLUMN_NAME, :datetime_with_timezone)
    end
  end

  def down
    with_lock_retries do
      remove_column TABLE_NAME, COLUMN_NAME
    end
  end
end
