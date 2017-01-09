class AddGithubCompatibleToWebHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :github_compatible, :boolean, default: false, null: false
  end
end
