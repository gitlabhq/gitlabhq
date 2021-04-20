# frozen_string_literal: true

class RemoveMembersIndexOnUserId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_members_on_user_id'

  def up
    remove_concurrent_index_by_name(:members, INDEX_NAME)
  end

  def down
    add_concurrent_index(:members, :user_id, name: INDEX_NAME)
  end
end
