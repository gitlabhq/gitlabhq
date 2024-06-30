# frozen_string_literal: true

class AddAiActionRateLimitToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :application_settings, :ai_action_api_rate_limit, :integer, default: 160, null: false
  end
end
