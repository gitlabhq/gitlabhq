# frozen_string_literal: true

class AddStatusExpiresAtToUserStatuses < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column(:user_statuses, :clear_status_at, :datetime_with_timezone, null: true)
    end
  end

  def down
    with_lock_retries do
      remove_column(:user_statuses, :clear_status_at)
    end
  end
end
