# frozen_string_literal: true

class AddProjectBfgObjectMapColumn < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddColumnsToWideTables
  # rubocop:disable Migration/AddLimitToStringColumns
  def change
    add_column :projects, :bfg_object_map, :string
  end
  # rubocop:enable Migration/AddColumnsToWideTables
  # rubocop:enable Migration/AddLimitToStringColumns
end
