# frozen_string_literal: true

class AddRateLimitsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  enable_lock_retries!

  def change
    add_column :application_settings, :rate_limits, :jsonb, default: {}, null: false
  end
end
