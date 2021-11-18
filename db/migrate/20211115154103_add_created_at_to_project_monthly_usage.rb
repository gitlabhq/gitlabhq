# frozen_string_literal: true

class AddCreatedAtToProjectMonthlyUsage < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :ci_project_monthly_usages, :created_at, :datetime_with_timezone
    end
  end

  def down
    with_lock_retries do
      remove_column :ci_project_monthly_usages, :created_at
    end
  end
end
