# frozen_string_literal: true

class AddGroupIdAndUserTypeToPersonalAccessTokens < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :personal_access_tokens, :group_id, :bigint
    add_column :personal_access_tokens, :user_type, :integer, limit: 2
  end
end
