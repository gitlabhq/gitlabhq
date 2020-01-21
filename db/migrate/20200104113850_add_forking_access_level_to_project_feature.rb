# frozen_string_literal: true

class AddForkingAccessLevelToProjectFeature < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    add_column :project_features, :forking_access_level, :integer
  end
end
