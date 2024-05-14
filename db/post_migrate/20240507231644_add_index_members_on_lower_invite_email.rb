# frozen_string_literal: true

class AddIndexMembersOnLowerInviteEmail < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  INDEX_NAME = 'index_members_on_lower_invite_email'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, '(lower(invite_email))', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
