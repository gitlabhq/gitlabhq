# frozen_string_literal: true

class AddAdvancedTokenScope < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.1'

  def up
    with_lock_retries do
      add_column :personal_access_tokens, :advanced_scopes, :text, if_not_exists: true
    end

    add_text_limit :personal_access_tokens, :advanced_scopes, 4096
  end

  def down
    with_lock_retries do
      remove_column :personal_access_tokens, :advanced_scopes, if_exists: true
    end
  end
end
