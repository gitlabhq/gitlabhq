class AddBitbucketAccessTokenAndSecretToUser < ActiveRecord::Migration
  def change
    add_column :users, :bitbucket_access_token, :string
    add_column :users, :bitbucket_access_token_secret, :string
  end
end
