# frozen_string_literal: true

class ChangePublicProjectsMinutesCostFactorDefaultTo1 < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      change_column_default :ci_runners, :public_projects_minutes_cost_factor, from: 0.0, to: 1.0
    end
  end

  def down
    with_lock_retries do
      change_column_default :ci_runners, :public_projects_minutes_cost_factor, from: 1.0, to: 0.0
    end
  end
end
