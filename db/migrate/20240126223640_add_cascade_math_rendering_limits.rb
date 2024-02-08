# frozen_string_literal: true

class AddCascadeMathRenderingLimits < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  enable_lock_retries!

  def change
    add_column :namespace_settings, :math_rendering_limits_enabled, :boolean, null: true
    add_column :namespace_settings, :lock_math_rendering_limits_enabled, :boolean, default: false, null: false
    add_column :application_settings, :lock_math_rendering_limits_enabled, :boolean, default: false, null: false
  end
end
