# frozen_string_literal: true

class AddProjectBfgObjectMapColumn < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/PreventStrings
  def change
    add_column :projects, :bfg_object_map, :string
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/AddColumnsToWideTables
end
