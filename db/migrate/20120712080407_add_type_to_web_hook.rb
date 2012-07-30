class AddTypeToWebHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :type, :string, :default => "ProjectHook"
  end
end
