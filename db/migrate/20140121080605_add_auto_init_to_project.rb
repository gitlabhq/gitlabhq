class AddAutoInitToProject < ActiveRecord::Migration
  def change
    add_column :projects, :auto_init, :boolean, :default => true, :null => false
  end
end
