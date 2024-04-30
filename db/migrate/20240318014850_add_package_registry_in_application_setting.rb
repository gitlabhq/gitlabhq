# frozen_string_literal: true

class AddPackageRegistryInApplicationSetting < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_package_registry_is_hash'

  def up
    add_column :application_settings, :package_registry, :jsonb, default: {}, null: false
    add_check_constraint(:application_settings, "(jsonb_typeof(package_registry) = 'object')", CONSTRAINT_NAME)
  end

  def down
    remove_column :application_settings, :package_registry
  end
end
