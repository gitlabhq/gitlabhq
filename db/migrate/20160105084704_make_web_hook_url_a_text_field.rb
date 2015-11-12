class MakeWebHookUrlATextField < ActiveRecord::Migration
  def change
    change_column :web_hooks, :url, :text
  end
end
