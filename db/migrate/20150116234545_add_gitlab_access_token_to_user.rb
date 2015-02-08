class AddGitlabAccessTokenToUser < ActiveRecord::Migration
  def change
    add_column :users, :gitlab_access_token, :string
  end
end
