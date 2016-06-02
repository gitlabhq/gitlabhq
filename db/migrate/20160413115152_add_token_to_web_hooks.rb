class AddTokenToWebHooks < ActiveRecord::Migration
  def change
    add_column :web_hooks, :token, :string
  end
end
