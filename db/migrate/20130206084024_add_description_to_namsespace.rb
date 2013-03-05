class AddDescriptionToNamsespace < ActiveRecord::Migration
  def change
    add_column :namespaces, :description, :string, default: '', null: false
  end
end
