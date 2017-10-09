# rubocop:disable all
class AddPublicToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :public, :boolean, default: false, null: false
  end
end
