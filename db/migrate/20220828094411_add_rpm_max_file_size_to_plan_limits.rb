# frozen_string_literal: true

class AddRpmMaxFileSizeToPlanLimits < Gitlab::Database::Migration[2.0]
  DOWNTIME = false

  def change
    add_column :plan_limits, :rpm_max_file_size, :bigint, default: 5.gigabytes, null: false
  end
end
