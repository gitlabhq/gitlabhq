# frozen_string_literal: true

class AddDescriptionToPersonalAccessTokens < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.7'

  def up
    with_lock_retries do
      add_column :personal_access_tokens, :description, :text, if_not_exists: true
    end

    add_text_limit :personal_access_tokens, :description, 255
  end

  def down
    with_lock_retries do
      remove_column :personal_access_tokens, :description, if_exists: true
    end
  end
end
