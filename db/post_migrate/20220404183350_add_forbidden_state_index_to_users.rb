# frozen_string_literal: true

class AddForbiddenStateIndexToUsers < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'users_forbidden_state_idx'

  def up
    add_concurrent_index :users, :id,
      name: INDEX_NAME,
      where: "confirmed_at IS NOT NULL AND (state <> ALL (ARRAY['blocked', 'banned', 'ldap_blocked']))"
  end

  def down
    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
