class AddTokenToWebHooks < ActiveRecord::Migration[4.2]
  def change
    add_column :web_hooks, :token, :string
  end
end
