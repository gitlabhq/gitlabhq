# frozen_string_literal: true

class AddFkToPersonalAccessTokensOnPreviousPersonalAccessTokenId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :personal_access_tokens,
      :personal_access_tokens,
      column: :previous_personal_access_token_id,
      on_delete: :nullify)
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :personal_access_tokens, column: :previous_personal_access_token_id
    end
  end
end
