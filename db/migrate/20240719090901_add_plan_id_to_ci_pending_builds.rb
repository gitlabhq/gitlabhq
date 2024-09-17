# frozen_string_literal: true

class AddPlanIdToCiPendingBuilds < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  enable_lock_retries!

  def change
    add_column :ci_pending_builds, :plan_id, :integer, null: true
  end
end
