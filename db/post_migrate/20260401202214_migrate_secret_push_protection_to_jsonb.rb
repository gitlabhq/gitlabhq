# frozen_string_literal: true

class MigrateSecretPushProtectionToJsonb < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    execute(<<~SQL)
      UPDATE application_settings
      SET security_and_compliance_settings = jsonb_set(
        jsonb_set(
          COALESCE(security_and_compliance_settings, '{}'::jsonb),
          '{secret_push_protection_available}',
          to_jsonb(COALESCE(secret_push_protection_available, false))
        ),
        '{secret_push_protection_enforced}',
        'false'::jsonb
      )
    SQL
  end

  def down
    execute(<<~SQL)
      UPDATE application_settings
      SET security_and_compliance_settings = COALESCE(security_and_compliance_settings, '{}'::jsonb) - 'secret_push_protection_available' - 'secret_push_protection_enforced'
    SQL
  end
end
