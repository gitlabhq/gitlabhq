# frozen_string_literal: true

class AddPackageRegistryAllowAnyoneToPullOptionToApplicationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :application_settings, :package_registry_allow_anyone_to_pull_option, :boolean, null: false,
      default: true
  end
end
