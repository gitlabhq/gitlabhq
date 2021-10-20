# frozen_string_literal: true

class AddSharedRunnersDurationToCiProjectMonthlyUsages < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :ci_project_monthly_usages, :shared_runners_duration, :integer, default: 0, null: false
  end
end
