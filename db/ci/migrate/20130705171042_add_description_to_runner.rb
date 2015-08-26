class AddDescriptionToRunner < ActiveRecord::Migration
  def change
    add_column :runners, :description, :string
  end
end
