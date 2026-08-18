# frozen_string_literal: true

class RestoreAiInfrastructureSettingsFromAiSettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  DEFAULT_ORGANIZATION_ID = 1 # rubocop:disable Gitlab/AvoidConstDefaultOrganizationId -- migration reads the legacy instance-wide row, which lives on the default organization
  DEFAULT_TIMEOUT_SECONDS = 60

  class AiSetting < MigrationRecord
    self.table_name = 'ai_settings'
  end

  class ApplicationSetting < MigrationRecord
    self.table_name = 'application_settings'
  end

  def up
    AiSetting.reset_column_information
    ApplicationSetting.reset_column_information

    ai_setting = AiSetting.find_by(organization_id: DEFAULT_ORGANIZATION_ID) # rubocop:disable Gitlab/AvoidConstDefaultOrganizationId -- migration reads the legacy instance-wide row, which lives on the default organization

    return unless ai_setting

    ApplicationSetting.where(ai_gateway_url: nil).update_all(ai_gateway_url: ai_setting.ai_gateway_url)
    ApplicationSetting.where(ai_gateway_timeout_seconds: DEFAULT_TIMEOUT_SECONDS)
      .update_all(ai_gateway_timeout_seconds: ai_setting.ai_gateway_timeout_seconds || DEFAULT_TIMEOUT_SECONDS)
    ApplicationSetting.where(enabled_instance_verbose_ai_logs: false)
      .update_all(enabled_instance_verbose_ai_logs: !!ai_setting.enabled_instance_verbose_ai_logs)
    ApplicationSetting.where(duo_agent_platform_service_url: nil)
      .update_all(duo_agent_platform_service_url: ai_setting.duo_agent_platform_service_url)
    ApplicationSetting.where(self_hosted_duo_agent_platform_service_secure: true)
      .update_all(
        self_hosted_duo_agent_platform_service_secure:
          ai_setting.self_hosted_duo_agent_platform_service_secure.nil? ||
          ai_setting.self_hosted_duo_agent_platform_service_secure
      )
  end

  def down
    # no-op: the source columns on ai_settings are not modified by `up`
  end
end
