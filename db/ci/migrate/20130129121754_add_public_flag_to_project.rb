class AddPublicFlagToProject < ActiveRecord::Migration
  def change
    add_column :projects, :public, :boolean, null: false, default: false
  end
end
