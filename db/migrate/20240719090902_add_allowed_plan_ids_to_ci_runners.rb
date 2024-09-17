# frozen_string_literal: true

class AddAllowedPlanIdsToCiRunners < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  enable_lock_retries!

  def change
    add_column :ci_runners, :allowed_plan_ids, :integer, array: true, null: false, default: []
  end
end
