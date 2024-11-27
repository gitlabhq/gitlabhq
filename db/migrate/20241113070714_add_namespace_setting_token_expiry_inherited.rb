# frozen_string_literal: true

class AddNamespaceSettingTokenExpiryInherited < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  # not using the CascadingNamespaceSettings helper here, since the application_settings changes are
  # in a jsonb column
  def change
    add_column :namespace_settings, :resource_access_token_notify_inherited, :boolean
    add_column :namespace_settings, :lock_resource_access_token_notify_inherited, :boolean, default: false, null: false
  end
end
