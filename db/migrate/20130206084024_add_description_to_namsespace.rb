# rubocop:disable all
class AddDescriptionToNamsespace < ActiveRecord::Migration[4.2]
  def change
    add_column :namespaces, :description, :string, default: '', null: false
  end
end
