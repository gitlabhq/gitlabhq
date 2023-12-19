# frozen_string_literal: true

class RemoveApplicationSettingsColumns < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  def up
    remove_column :application_settings, :elasticsearch_shards, if_exists: true
    remove_column :application_settings, :elasticsearch_replicas, if_exists: true
    remove_column :application_settings, :static_objects_external_storage_auth_token, if_exists: true
    remove_column :application_settings, :web_ide_clientside_preview_enabled, if_exists: true
  end

  def down
    add_column :application_settings, :elasticsearch_shards, :integer, default: 5, null: false, if_not_exists: true
    add_column :application_settings, :elasticsearch_replicas, :integer, default: 1, null: false, if_not_exists: true
    add_column :application_settings, :static_objects_external_storage_auth_token, :string, limit: 255,
      if_not_exists: true
    add_column :application_settings, :web_ide_clientside_preview_enabled, :boolean, default: false, null: false,
      if_not_exists: true
  end
end
