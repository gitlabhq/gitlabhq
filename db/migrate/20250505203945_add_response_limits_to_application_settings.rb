# frozen_string_literal: true

class AddResponseLimitsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    add_column :application_settings, :response_limits, :jsonb, default: {}, null: false
  end
end
