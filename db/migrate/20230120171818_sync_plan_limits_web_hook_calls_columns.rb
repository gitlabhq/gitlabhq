# frozen_string_literal: true

class SyncPlanLimitsWebHookCallsColumns < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute('UPDATE plan_limits SET web_hook_calls=web_hook_calls_high')
  end

  def down
    # noop
  end
end
