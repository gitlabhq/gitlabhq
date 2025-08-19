# frozen_string_literal: true

class IndexPersonalAccessTokensOnGroupId < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_personal_access_tokens_on_group_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- index is needed for the foreign key
    add_concurrent_index :personal_access_tokens, :group_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :personal_access_tokens, INDEX_NAME
  end
end
