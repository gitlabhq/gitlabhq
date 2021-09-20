# frozen_string_literal: true

class AddYamlLimitsApplicationSetting < ActiveRecord::Migration[6.1]
  DOWNTIME = false

  def change
    add_column :application_settings, :max_yaml_size_bytes, :bigint, default: 1.megabyte, null: false
    add_column :application_settings, :max_yaml_depth, :integer, default: 100, null: false
  end
end
