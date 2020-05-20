# frozen_string_literal: true

class AddOffsetPaginationPlanLimit < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :offset_pagination_limit, :integer, default: 50000, null: false
  end
end
