# frozen_string_literal: true

class AddStorageSizeLimitToPlanLimit < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :storage_size_limit, :integer, default: 0, null: false
  end
end
