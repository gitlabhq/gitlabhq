class AddColumnRevokedToPersonalAccessTokens < ActiveRecord::Migration
  def change
    add_column :personal_access_tokens, :revoked, :boolean, default: false
  end
end
