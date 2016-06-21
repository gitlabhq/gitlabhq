# rubocop:disable all
class AddPublicToProject < ActiveRecord::Migration
  def change
    add_column :projects, :public, :boolean, default: false, null: false
  end
end
