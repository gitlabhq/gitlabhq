# frozen_string_literal: true

class AddDuoAgentPlatformServiceUrlToAiSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.4'

  def up
    with_lock_retries do
      add_column :ai_settings, :duo_agent_platform_service_url, :text, if_not_exists: true
    end

    add_text_limit :ai_settings, :duo_agent_platform_service_url, 2048
  end

  def down
    with_lock_retries do
      remove_column :ai_settings, :duo_agent_platform_service_url, if_exists: true
    end
  end
end
