class AddPrivateLimit < ActiveRecord::Migration
  def change
    add_column :users, :projects_limit_priv, :integer, default: 5, null: true
  end
end
