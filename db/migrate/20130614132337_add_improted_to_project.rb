# rubocop:disable all
class AddImprotedToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :imported, :boolean, default: false, null: false
  end
end
