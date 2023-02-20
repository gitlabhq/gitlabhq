# frozen_string_literal: true

class RenameWebHookCallsToWebHookCallsHigh < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :plan_limits, :web_hook_calls, :web_hook_calls_high
  end

  def down
    undo_rename_column_concurrently :plan_limits, :web_hook_calls, :web_hook_calls_high
  end
end
