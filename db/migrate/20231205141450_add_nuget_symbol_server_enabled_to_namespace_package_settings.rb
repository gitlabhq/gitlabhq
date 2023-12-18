# frozen_string_literal: true

class AddNugetSymbolServerEnabledToNamespacePackageSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  def up
    with_lock_retries do
      add_column :namespace_package_settings, :nuget_symbol_server_enabled, :boolean, default: false, null: false,
        if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_package_settings, :nuget_symbol_server_enabled, if_exists: true
    end
  end
end
