# frozen_string_literal: true

class AddUsagePingGenerationEnabledToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column(:application_settings, :usage_ping_generation_enabled, :boolean, default: true, null: false)
  end
end
