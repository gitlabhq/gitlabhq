# frozen_string_literal: true

class AddRegistryMigrationPreImportTagsRateToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :container_registry_pre_import_tags_rate,
               :decimal,
               precision: 6,
               scale: 2,
               default: 0.5,
               null: false
  end
end
