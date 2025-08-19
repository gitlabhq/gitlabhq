# frozen_string_literal: true

class AddForeignKeyToPersonalAccessTokensGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :personal_access_tokens, :namespaces, column: :group_id, on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key :personal_access_tokens, column: :group_id
    end
  end
end
