# rubocop:disable all
class AddPublicToKey < ActiveRecord::Migration[4.2]
  def change
    add_column :keys, :public, :boolean, default: false, null: false
  end
end
