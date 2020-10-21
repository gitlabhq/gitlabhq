# frozen_string_literal: true

class AddDebianMaxFileSizeToPlanLimits < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :debian_max_file_size, :bigint, default: 3.gigabytes, null: false
  end
end
