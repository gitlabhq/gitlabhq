class RenameGitlabUrlToPath < ActiveRecord::Migration
  def change
    rename_column :projects, :gitlab_url, :path
  end
end
