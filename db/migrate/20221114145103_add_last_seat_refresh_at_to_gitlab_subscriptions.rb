# frozen_string_literal: true

class AddLastSeatRefreshAtToGitlabSubscriptions < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  TABLE_NAME = 'gitlab_subscriptions'
  COLUMN_NAME = 'last_seat_refresh_at'

  def up
    add_column(TABLE_NAME, COLUMN_NAME, :datetime_with_timezone)
  end

  def down
    remove_column(TABLE_NAME, COLUMN_NAME)
  end
end
