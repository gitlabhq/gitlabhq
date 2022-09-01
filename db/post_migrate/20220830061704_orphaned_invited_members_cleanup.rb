# frozen_string_literal: true

class OrphanedInvitedMembersCleanup < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # rubocop:disable Style/SymbolProc
    membership.where(query_condition).each_batch(of: 100) do |relation|
      relation.delete_all
    end
    # rubocop:enable Style/SymbolProc
  end

  def down
    # This migration is irreversible
  end

  private

  def membership
    @membership ||= define_batchable_model('members')
  end

  def query_condition
    'invite_token IS NULL and invite_accepted_at IS NOT NULL AND user_id IS NULL'
  end
end
