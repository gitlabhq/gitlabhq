# frozen_string_literal: true

class AddCiNeedsSizeLimitToPlanLimit < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :ci_needs_size_limit, :integer, default: 50, null: false
  end
end
