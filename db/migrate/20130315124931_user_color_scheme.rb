class UserColorScheme < ActiveRecord::Migration
  include Gitlab::Database

  def up
    add_column :users, :color_scheme_id, :integer, null: false, default: 1
    execute("UPDATE users SET color_scheme_id = 2 WHERE dark_scheme = #{true_value}")
    remove_column :users, :dark_scheme
  end

  def down
    add_column :users, :dark_scheme, :boolean, null: false, default: false
    remove_column :users, :color_scheme_id
  end
end
