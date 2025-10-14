# frozen_string_literal: true

class IndexPersonalAccessTokensOnGroupIdAndUserTypeAndLastUsedAtAndId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.5'

  INDEX_NAME = 'index_pats_on_group_id_and_user_type_and_last_used_at_and_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- index is needed for Credentials inventory
    add_concurrent_index(
      :personal_access_tokens,
      [:group_id, :user_type, :last_used_at, :id],
      where: 'impersonation = false',
      name: INDEX_NAME
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
