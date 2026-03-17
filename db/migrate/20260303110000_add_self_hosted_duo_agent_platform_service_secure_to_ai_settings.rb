# frozen_string_literal: true

class AddSelfHostedDuoAgentPlatformServiceSecureToAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :ai_settings, :self_hosted_duo_agent_platform_service_secure, :boolean, default: true, null: false
  end
end
