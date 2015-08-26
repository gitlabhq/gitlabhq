class AddGitlabUrlToProject < ActiveRecord::Migration
  def change
    add_column :projects, :gitlab_url, :string, null: true
  end
end
