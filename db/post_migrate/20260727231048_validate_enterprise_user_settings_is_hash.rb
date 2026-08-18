# frozen_string_literal: true

class ValidateEnterpriseUserSettingsIsHash < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    validate_check_constraint :namespace_settings,
      'check_namespace_settings_enterprise_user_settings_is_hash'
  end

  def down
    # no-op
  end
end
