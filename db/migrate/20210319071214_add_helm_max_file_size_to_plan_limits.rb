# frozen_string_literal: true

class AddHelmMaxFileSizeToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :helm_max_file_size, :bigint, default: 5.megabyte, null: false
  end
end
