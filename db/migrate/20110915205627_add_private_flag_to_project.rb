class AddPrivateFlagToProject < ActiveRecord::Migration
  def change
    add_column :projects, :private_flag, :boolean, :default => true, :null => false
  end
end
