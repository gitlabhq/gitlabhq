# frozen_string_literal: true

class RemovePlanLimitsCiActivePipelinesColumn < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    remove_column :plan_limits, :ci_active_pipelines
  end

  def down
    add_column :plan_limits, :ci_active_pipelines, :integer, default: 0, null: false
  end
end
