# frozen_string_literal: true

class AddSharedRunnersDurationToCiNamespaceMonthlyUsages < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :ci_namespace_monthly_usages, :shared_runners_duration, :integer, default: 0, null: false
  end
end
