# frozen_string_literal: true

class RemoveTemporaryIndexForOrphanedInvitedMembers < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  TMP_INDEX_NAME = 'tmp_idx_orphaned_invited_members'

  def up
    remove_concurrent_index_by_name('members', TMP_INDEX_NAME) if index_exists_by_name?('members', TMP_INDEX_NAME)
  end

  def down
    add_concurrent_index('members', :id, where: query_condition, name: TMP_INDEX_NAME)
  end

  private

  def query_condition
    'invite_token IS NULL and invite_accepted_at IS NOT NULL AND user_id IS NULL'
  end
end
