# frozen_string_literal: true

class AddIndexForActiveMembers < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_members_on_source_state_type_access_level_and_user_id'

  disable_ddl_transaction!

  def up
    where_clause = 'requested_at is null and invite_token is null'

    add_concurrent_index :members, [:source_id, :source_type, :state, :type, :access_level, :user_id],
                         name: INDEX_NAME, where: where_clause
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
