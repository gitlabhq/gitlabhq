# frozen_string_literal: true

class AddIndexToMembersForUnacceptedInvitations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'idx_members_created_at_user_id_invite_token'
  INDEX_SCOPE = 'invite_token IS NOT NULL AND user_id IS NULL'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:members, :created_at, where: INDEX_SCOPE, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:members, :created_at, where: INDEX_SCOPE, name: INDEX_NAME)
  end
end
