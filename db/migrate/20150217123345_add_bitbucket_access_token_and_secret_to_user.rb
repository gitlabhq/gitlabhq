class AddBitbucketAccessTokenAndSecretToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :bitbucket_access_token, :string
    add_column :users, :bitbucket_access_token_secret, :string
  end
end
