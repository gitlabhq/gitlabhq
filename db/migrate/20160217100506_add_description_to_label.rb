class AddDescriptionToLabel < ActiveRecord::Migration[4.2]
  def change
    add_column :labels, :description, :string
  end
end
