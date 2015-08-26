class AddOptionsToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :options, :text
  end
end
