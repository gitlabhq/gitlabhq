# frozen_string_literal: true

class RemoveIndexForRequestedNonInvitedAwaitingMembers < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_members_on_non_requested_non_invited_and_state_awaiting'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :members, INDEX_NAME
  end

  def down
    clause = '((requested_at IS NULL) AND (invite_token IS NULL) AND (access_level > 5) AND (state = 1))'

    add_concurrent_index :members, :source_id, where: clause, name: INDEX_NAME
  end
end
