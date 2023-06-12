# frozen_string_literal: true

class ChangeNotifiedOfOwnActivityDefault < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    change_column_default(:users, :notified_of_own_activity, from: nil, to: false)
  end
end
