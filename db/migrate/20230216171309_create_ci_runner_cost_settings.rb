# frozen_string_literal: true

class CreateCiRunnerCostSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :ci_cost_settings, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :runner, null: false, primary_key: true, index: false,
        foreign_key: { to_table: :ci_runners, on_delete: :cascade },
        type: :bigint, default: nil
      t.float :standard_factor, null: false, default: 1.00
      t.float :os_contribution_factor, null: false, default: 0.008
      t.float :os_plan_factor, null: false, default: 0.5
    end
  end
end
