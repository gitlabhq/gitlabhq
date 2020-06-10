# frozen_string_literal: true

class AddContainerRegistryFeaturesToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    add_column :application_settings, :container_registry_features, :text, array: true, default: [], null: false
  end

  def down
    remove_column :application_settings, :container_registry_features
  end
end
