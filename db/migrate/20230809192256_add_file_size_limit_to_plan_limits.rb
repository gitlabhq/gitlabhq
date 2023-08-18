# frozen_string_literal: true

class AddFileSizeLimitToPlanLimits < Gitlab::Database::Migration[2.1]
  def change
    add_column :plan_limits, :file_size_limit_mb, :float, default: 100, null: false
  end
end
