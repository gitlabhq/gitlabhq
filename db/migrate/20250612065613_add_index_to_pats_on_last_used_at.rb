# frozen_string_literal: true

class AddIndexToPatsOnLastUsedAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.2'

  INDEX_NAME = 'index_pats_on_user_id_and_last_used_at_and_pat_id'

  def up
    add_concurrent_index( # rubocop:disable Migration/PreventIndexCreation -- PATs are not in the high traffic table list
      :personal_access_tokens,
      [:user_id, :last_used_at, :id],
      where: 'impersonation = false',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(:personal_access_tokens, INDEX_NAME)
  end
end
