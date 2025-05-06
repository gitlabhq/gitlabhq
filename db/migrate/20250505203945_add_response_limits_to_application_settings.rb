# frozen_string_literal: true

class AddResponseLimitsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :application_settings, :response_limits, :jsonb, default: {}, null: false
  end
end
