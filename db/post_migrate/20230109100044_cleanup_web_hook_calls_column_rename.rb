# frozen_string_literal: true

class CleanupWebHookCallsColumnRename < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :plan_limits, :web_hook_calls, :web_hook_calls_high
  end

  def down
    undo_cleanup_concurrent_column_rename :plan_limits, :web_hook_calls, :web_hook_calls_high
  end
end
