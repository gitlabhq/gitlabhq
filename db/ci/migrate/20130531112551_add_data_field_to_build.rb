class AddDataFieldToBuild < ActiveRecord::Migration
  def change
    add_column :builds, :push_data, :text
  end
end
