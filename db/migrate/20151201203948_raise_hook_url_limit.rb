class RaiseHookUrlLimit < ActiveRecord::Migration
  def change
    change_column :web_hooks, :url, :string, limit: 2000
  end
end
