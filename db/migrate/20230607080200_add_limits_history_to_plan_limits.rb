# frozen_string_literal: true

class AddLimitsHistoryToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column :plan_limits, :limits_history, :jsonb, default: {}, null: false
  end
end
