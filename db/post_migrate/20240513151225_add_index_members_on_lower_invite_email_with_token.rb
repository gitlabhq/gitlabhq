# frozen_string_literal: true

class AddIndexMembersOnLowerInviteEmailWithToken < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  OLD_INDEX_NAME = 'index_members_on_lower_invite_email'
  INDEX_NAME = 'index_members_on_lower_invite_email_with_token'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, '(lower(invite_email))', where: 'invite_token IS NOT NULL', name: INDEX_NAME

    remove_concurrent_index_by_name :members, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :members, '(lower(invite_email))', name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
