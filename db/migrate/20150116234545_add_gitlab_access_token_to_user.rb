class AddGitlabAccessTokenToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :gitlab_access_token, :string
  end
end
