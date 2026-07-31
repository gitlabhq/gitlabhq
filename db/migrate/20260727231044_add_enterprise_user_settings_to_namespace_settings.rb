# frozen_string_literal: true

class AddEnterpriseUserSettingsToNamespaceSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.3'

  def change
    add_column :namespace_settings, :enterprise_user_settings, :jsonb,
      default: {}, null: false, if_not_exists: true

    add_check_constraint(
      :namespace_settings,
      "jsonb_typeof(enterprise_user_settings) = 'object'",
      'check_namespace_settings_enterprise_user_settings_is_hash',
      validate: false
    )
  end
end
