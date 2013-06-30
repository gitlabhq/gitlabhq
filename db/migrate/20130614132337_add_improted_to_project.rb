class AddImprotedToProject < ActiveRecord::Migration
  def change
    add_column :projects, :imported, :boolean, default: false, null: false
  end
end
