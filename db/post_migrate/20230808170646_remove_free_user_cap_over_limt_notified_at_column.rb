# frozen_string_literal: true

class RemoveFreeUserCapOverLimtNotifiedAtColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    remove_column :namespace_details, :free_user_cap_over_limt_notified_at, :datetime_with_timezone
  end
end
