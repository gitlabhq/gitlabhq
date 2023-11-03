# frozen_string_literal: true

class AsyncDropIndexUsersOnAcceptedTermId < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  TABLE_NAME = 'users'
  INDEX_NAME = 'index_users_on_accepted_term_id'
  COLUMN = 'accepted_term_id'

  # TODO: Index to be destroyed synchronously in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135293
  def up
    prepare_async_index_removal TABLE_NAME, COLUMN, name: INDEX_NAME
  end

  def down
    prepare_async_index_removal TABLE_NAME, COLUMN, name: INDEX_NAME
  end
end
