class AddAllowGitFetchToProject < ActiveRecord::Migration
  def change
    add_column :projects, :allow_git_fetch, :boolean, default: true, null: false
  end
end
