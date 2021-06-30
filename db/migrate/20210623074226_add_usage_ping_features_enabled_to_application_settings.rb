# frozen_string_literal: true

class AddUsagePingFeaturesEnabledToApplicationSettings < ActiveRecord::Migration[6.1]
  def up
    add_column :application_settings, :usage_ping_features_enabled, :boolean, default: false, null: false
  end

  def down
    remove_column :application_settings, :usage_ping_features_enabled
  end
end
