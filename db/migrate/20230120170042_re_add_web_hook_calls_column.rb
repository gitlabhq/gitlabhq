# frozen_string_literal: true

class ReAddWebHookCallsColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :plan_limits, :web_hook_calls, :integer, default: 0, null: false, if_not_exists: true
  end
end
