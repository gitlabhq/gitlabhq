# frozen_string_literal: true

class AddEnforceNamespaceStorageLimitToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :enforce_namespace_storage_limit, :boolean, default: false, null: false
  end
end
