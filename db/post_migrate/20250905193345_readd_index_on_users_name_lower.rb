# frozen_string_literal: true

class ReaddIndexOnUsersNameLower < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  INDEX_NAME = 'index_on_users_name_lower'

  def up
    # This index was added in GitLab 10.5 with
    # https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17158,
    # but it was gated on a `Gitlab::Database.postgresql?` check. We've seen
    # some older installations missing this index.
    return if index_exists_by_name?(:users, INDEX_NAME)

    add_concurrent_index :users, 'LOWER(name)', name: INDEX_NAME # rubocop:disable Migration/PreventIndexCreation -- This index should have already existed
  end

  def down; end
end
