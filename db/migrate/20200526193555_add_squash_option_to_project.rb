# frozen_string_literal: true

class AddSquashOptionToProject < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :project_settings, :squash_option, :integer, default: 3, limit: 2
  end
end
