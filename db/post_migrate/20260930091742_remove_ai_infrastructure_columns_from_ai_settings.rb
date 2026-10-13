# frozen_string_literal: true

class RemoveAiInfrastructureColumnsFromAiSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  def up
    with_lock_retries do
      remove_column :ai_settings, :ai_gateway_url, if_exists: true
      remove_column :ai_settings, :ai_gateway_timeout_seconds, if_exists: true
      remove_column :ai_settings, :enabled_instance_verbose_ai_logs, if_exists: true
      remove_column :ai_settings, :duo_agent_platform_service_url, if_exists: true
      remove_column :ai_settings, :self_hosted_duo_agent_platform_service_secure, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :ai_settings, :ai_gateway_url, :text, if_not_exists: true
      add_column :ai_settings, :ai_gateway_timeout_seconds, :integer, default: 60, if_not_exists: true
      add_column :ai_settings, :enabled_instance_verbose_ai_logs, :boolean, if_not_exists: true
      add_column :ai_settings, :duo_agent_platform_service_url, :text, if_not_exists: true
      add_column :ai_settings, :self_hosted_duo_agent_platform_service_secure, :boolean,
        default: true, null: false, if_not_exists: true
    end

    add_text_limit :ai_settings, :ai_gateway_url, 2048
    add_text_limit :ai_settings, :duo_agent_platform_service_url, 2048
  end
end
