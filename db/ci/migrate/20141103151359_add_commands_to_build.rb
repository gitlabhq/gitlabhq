class AddCommandsToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :commands, :text
  end
end
