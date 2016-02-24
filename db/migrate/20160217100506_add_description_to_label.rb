class AddDescriptionToLabel < ActiveRecord::Migration
  def change
    add_column :labels, :description, :string
  end
end
