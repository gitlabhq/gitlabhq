# frozen_string_literal: true

class OrphanedInviteTokensCleanup < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TMP_INDEX_NAME = 'tmp_idx_orphaned_invite_tokens'
  QUERY_CONDITION = "invite_token IS NOT NULL and invite_accepted_at IS NOT NULL and invite_accepted_at < created_at"

  def up
    membership = define_batchable_model('members')

    add_concurrent_index('members', :id, where: QUERY_CONDITION, name: TMP_INDEX_NAME)

    membership.where(QUERY_CONDITION).pluck(:id).each_slice(10) do |group|
      membership.where(id: group).where(QUERY_CONDITION).update_all(invite_token: nil)
    end

    remove_concurrent_index_by_name('members', TMP_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name('members', TMP_INDEX_NAME) if index_exists_by_name?('members', TMP_INDEX_NAME)

    # This migration is irreversible
  end
end
