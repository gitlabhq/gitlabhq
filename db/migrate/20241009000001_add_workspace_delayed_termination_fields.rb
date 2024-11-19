# frozen_string_literal: true

class AddWorkspaceDelayedTerminationFields < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      # Default max_active_hours_before_stop to 1.5 days, so that workspace should usually
      # stop outside of working hours, assuming it was last restarted during working hours.
      add_column :workspaces_agent_configs, :max_active_hours_before_stop, :smallint, default: 36, null: false,
        if_not_exists: true
      # Default max_stopped_hours_before_termination to 1 month (31 days)
      add_column :workspaces_agent_configs, :max_stopped_hours_before_termination, :smallint, default: 744, null: false,
        if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :workspaces_agent_configs, :max_active_hours_before_stop, if_exists: true
      remove_column :workspaces_agent_configs, :max_stopped_hours_before_termination, if_exists: true
    end
  end
end
