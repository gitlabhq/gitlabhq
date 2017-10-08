# rubocop:disable all
class AddPublicToGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :namespaces, :public, :boolean, default: false
  end
end
