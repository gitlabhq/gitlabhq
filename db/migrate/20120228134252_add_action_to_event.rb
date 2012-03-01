class AddActionToEvent < ActiveRecord::Migration
  def change
    add_column :events, :action, :integer, :null => true
  end
end
