# frozen_string_literal: true

class DropIndexPatsOnUserIdAndLastUsedAtAndPatId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  INDEX_NAME = 'index_pats_on_user_id_and_last_used_at_and_pat_id'

  def up
    remove_concurrent_index_by_name(:personal_access_tokens, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :personal_access_tokens,
      [:user_id, :last_used_at, :id],
      where: 'impersonation = false',
      name: INDEX_NAME
    )
  end
end
