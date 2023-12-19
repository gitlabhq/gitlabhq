# frozen_string_literal: true

class DropIndexUsersForbiddenState < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  INDEX_NAME = :users_forbidden_state_idx
  TABLE_NAME = :users

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    add_concurrent_index TABLE_NAME, :id,
      name: INDEX_NAME,
      where: "confirmed_at IS NOT NULL AND (state <> ALL (ARRAY['blocked', 'banned', 'ldap_blocked']))"
  end
end
