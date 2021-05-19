# frozen_string_literal: true

class AddWebHookCallsToPlanLimits < ActiveRecord::Migration[6.0]
  def change
    add_column :plan_limits, :web_hook_calls, :integer, null: false, default: 0
  end
end
