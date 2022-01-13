# frozen_string_literal: true

class AddTempIndexToMembersState < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_members_on_state'

  def up
    # Temporary index to be removed in 14.9 https://gitlab.com/gitlab-org/gitlab/-/issues/349960
    add_concurrent_index :members, :state, name: INDEX_NAME, where: 'state = 2'
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
