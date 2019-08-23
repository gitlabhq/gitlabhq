# frozen_string_literal: true

class AddProjectBfgObjectMapColumn < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :projects, :bfg_object_map, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
