# frozen_string_literal: true

class AddExpiryNotifiedAtToMember < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = 'members'
  COLUMN_NAME = 'expiry_notified_at'

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
