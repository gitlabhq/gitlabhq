# frozen_string_literal: true

class BackfillSelfHostedDuoAgentPlatformServiceSecureOnAiSettings < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    secure = to_boolean(ENV['DUO_AGENT_PLATFORM_SERVICE_SECURE'], default: true)

    execute <<~SQL
      UPDATE ai_settings
      SET self_hosted_duo_agent_platform_service_secure = #{connection.quote(secure)}
    SQL
  end

  def down
    # no-op
  end

  private

  def to_boolean(value, default: nil)
    value = value.to_s if [0, 1].include?(value)

    return value if [true, false].include?(value)
    return true if /^(true|t|yes|y|1|on)$/i.match?(value)
    return false if /^(false|f|no|n|0|off)$/i.match?(value)

    default
  end
end
