# frozen_string_literal: true

class AddWebHookCallsMedAndMaxToPlanLimits < Gitlab::Database::Migration[2.0]
  def change
    add_column :plan_limits, :web_hook_calls_mid, :integer, null: false, default: 0
    add_column :plan_limits, :web_hook_calls_low, :integer, null: false, default: 0
  end
end
