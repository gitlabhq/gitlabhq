# frozen_string_literal: true

class IndexMembersOnUserIdAccessLevelRequestedAtIsNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_members_on_user_id_and_access_level_requested_at_is_null'

  def up
    add_concurrent_index(:members, [:user_id, :access_level], where: 'requested_at IS NULL', name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:members, INDEX_NAME)
  end
end
