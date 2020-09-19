# frozen_string_literal: true

class ChangeBuildPendingStateEnums < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    change_column :ci_build_pending_states, :state, :integer, limit: 2
    change_column :ci_build_pending_states, :failure_reason, :integer, limit: 2
  end

  def down
    change_column :ci_build_pending_states, :state, :integer
    change_column :ci_build_pending_states, :failure_reason, :integer
  end
end
