# frozen_string_literal: true

class MigrateWebHookRateLimitFlagsToApplicationSettings < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '19.3'

  FLAG_TO_SETTING = {
    web_hook_event_resend_api_endpoint_rate_limit: 'web_hook_event_resend_limit',
    web_hook_test_api_endpoint_rate_limit: 'web_hook_test_limit'
  }.freeze

  def up
    FLAG_TO_SETTING.each do |flag_name, setting_name|
      # Both flags are default_enabled: true. Only an explicit, full disable
      # (a boolean=false gate) opted the instance out of the rate limit, and we
      # preserve that by disabling the limit (0). In every other case,
      # including percentage or actor gates, nothing is written and the
      # application setting default of 5 applies.
      next unless explicitly_disabled?(flag_name)

      execute(<<~SQL)
        UPDATE application_settings
        SET rate_limits = jsonb_set(
          COALESCE(rate_limits, '{}'::jsonb),
          '{#{setting_name}}',
          to_jsonb(0)
        ),
        updated_at = NOW()
        WHERE id = (SELECT MAX(id) FROM application_settings)
      SQL
    end
  end

  def down
    FLAG_TO_SETTING.each_value do |setting_name|
      execute(<<~SQL)
        UPDATE application_settings
        SET rate_limits = rate_limits - '#{setting_name}',
        updated_at = NOW()
        WHERE id = (SELECT MAX(id) FROM application_settings)
      SQL
    end
  end

  private

  def explicitly_disabled?(flag_name)
    feature_gates.where(feature_key: flag_name, key: 'boolean', value: 'false').exists?
  end
end
