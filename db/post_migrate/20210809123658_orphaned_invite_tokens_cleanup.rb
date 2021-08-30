# frozen_string_literal: true

class OrphanedInviteTokensCleanup < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  TMP_INDEX_NAME = 'tmp_idx_orphaned_invite_tokens'

  def up
    add_concurrent_index('members', :id, where: query_condition, name: TMP_INDEX_NAME)

    membership.where(query_condition).pluck(:id).each_slice(10) do |group|
      membership.where(id: group).where(query_condition).update_all(invite_token: nil)
    end

    remove_concurrent_index_by_name('members', TMP_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name('members', TMP_INDEX_NAME) if index_exists_by_name?('members', TMP_INDEX_NAME)

    # This migration is irreversible
  end

  private

  def membership
    @membership ||= define_batchable_model('members')
  end

  # We need to ensure we're comparing timestamp with time zones across
  # the board since that is an immutable comparison. Some database
  # schemas have a mix of timestamp without time zones and and timestamp
  # with time zones: https://gitlab.com/groups/gitlab-org/-/epics/2473
  def query_condition
    "invite_token IS NOT NULL and invite_accepted_at IS NOT NULL and #{timestamptz("invite_accepted_at")} < #{timestamptz("created_at")}"
  end

  def timestamptz(name)
    if column_type(name) == "timestamp without time zone"
      "TIMEZONE('UTC', #{name})"
    else
      name
    end
  end

  def column_type(name)
    membership.columns_hash[name].sql_type
  end
end
