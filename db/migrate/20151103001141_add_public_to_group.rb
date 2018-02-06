# rubocop:disable all
class AddPublicToGroup < ActiveRecord::Migration
  def change
    add_column :namespaces, :public, :boolean, default: false
  end
end
