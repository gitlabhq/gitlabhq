class AddPublicEnabledToProject < ActiveRecord::Migration
  def change
    add_column :projects, :public_enabled, :boolean, :default => false, :null => false
  end
end
