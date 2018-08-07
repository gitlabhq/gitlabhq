# frozen_string_literal: true

class AddRoadmapLayoutToUsers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :users, :roadmap_layout, :integer, limit: 2
  end
end
