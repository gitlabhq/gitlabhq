class UserColorScheme < ActiveRecord::Migration
  def up
    add_column :users, :color_scheme_id, :integer, null: false, default: 1
    User.where(dark_scheme: true).update_all(color_scheme_id: 2)
    remove_column :users, :dark_scheme
  end

  def down
    add_column :users, :dark_scheme, :boolean, null: false, default: false
    remove_column :users, :color_scheme_id
  end
end
