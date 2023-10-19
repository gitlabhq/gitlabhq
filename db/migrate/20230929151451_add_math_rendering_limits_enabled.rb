# frozen_string_literal: true

class AddMathRenderingLimitsEnabled < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :math_rendering_limits_enabled, :boolean, default: true, null: false
  end
end
