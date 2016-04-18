class AddColumnExpiresAtToPersonalAccessTokens < ActiveRecord::Migration
  def change
    add_column :personal_access_tokens, :expires_at, :datetime
  end
end
