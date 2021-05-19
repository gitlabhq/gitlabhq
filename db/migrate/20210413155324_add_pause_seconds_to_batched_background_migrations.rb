# frozen_string_literal: true

class AddPauseSecondsToBatchedBackgroundMigrations < ActiveRecord::Migration[6.0]
  def change
    add_column :batched_background_migrations, :pause_ms, :integer, null: false, default: 100
  end
end
