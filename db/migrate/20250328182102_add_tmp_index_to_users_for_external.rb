# frozen_string_literal: true

class AddTmpIndexToUsersForExternal < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.11'

  INDEX_NAME = 'tmp_index_users_on_external_where_external_is_null'

  def up
    return if Gitlab.com?

    # Temporary index to be removed in 18.1 https://gitlab.com/gitlab-org/gitlab/-/issues/527921

    add_concurrent_index :users, :external, where: 'external IS NULL', name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- Temporary index
  end

  def down
    return if Gitlab.com?

    remove_concurrent_index_by_name :users, INDEX_NAME
  end
end
