class AddStartedAtToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :started_at, :datetime, null: true
  end
end
