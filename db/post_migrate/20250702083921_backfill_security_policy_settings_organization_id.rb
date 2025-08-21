# frozen_string_literal: true

class BackfillSecurityPolicySettingsOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  DEFAULT_ORG_ID = 1

  def up
    # Backfill existing record with the default organization.
    # The setting is only used by self-managed until Organizations are ready.
    execute "UPDATE security_policy_settings SET organization_id = #{DEFAULT_ORG_ID}"
  end

  def down
    # noop
  end
end
