class AddPublicToKey < ActiveRecord::Migration
  def change
    add_column :keys, :public, :boolean, default: false, null: false
  end
end
