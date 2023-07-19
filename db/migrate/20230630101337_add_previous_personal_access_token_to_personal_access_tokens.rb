# frozen_string_literal: true

class AddPreviousPersonalAccessTokenToPersonalAccessTokens < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    add_column :personal_access_tokens, :previous_personal_access_token_id, :bigint, null: true
  end

  def down
    remove_column :personal_access_tokens, :previous_personal_access_token_id
  end
end
