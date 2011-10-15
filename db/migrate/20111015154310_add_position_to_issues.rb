class AddPositionToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :position, :integer, :default => 0
  end
end
