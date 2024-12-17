# frozen_string_literal: true

class AddResourceUsageLimitsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  enable_lock_retries!

  def change
    add_column :application_settings, :resource_usage_limits, :jsonb, default: {}, null: false
  end
end
