# frozen_string_literal: true

class DefaultCiConfigPath < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :application_settings, :default_ci_config_path, :string, limit: 255
  end

  def down
    remove_column :application_settings, :default_ci_config_path
  end
end
