class RaiseHookUrlLimit < ActiveRecord::Migration[4.2]
  def change
    change_column :web_hooks, :url, :string, limit: 2000
  end
end
