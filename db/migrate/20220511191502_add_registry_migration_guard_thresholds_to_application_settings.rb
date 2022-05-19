# frozen_string_literal: true

class AddRegistryMigrationGuardThresholdsToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :container_registry_pre_import_timeout,
               :integer,
               default: 30.minutes,
               null: false

    add_column :application_settings, :container_registry_import_timeout,
               :integer,
               default: 10.minutes,
               null: false
  end
end
