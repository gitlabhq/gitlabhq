# frozen_string_literal: true

class DefaultCiConfigPath < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def up
    add_column :application_settings, :default_ci_config_path, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings

  def down
    remove_column :application_settings, :default_ci_config_path
  end
end
