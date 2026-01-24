# frozen_string_literal: true

class ReplaceIndexForMembersRoleCounts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  OLD_INDEX = 'index_members_on_source_and_access_level_and_member_role'
  NEW_INDEX = 'index_members_on_source_access_level_user_id_member_role_null'

  def up
    columns = [:source_id, :source_type, :access_level, :user_id]
    add_concurrent_index :members, columns, where: 'member_role_id IS NULL', name: NEW_INDEX
    remove_concurrent_index_by_name :members, OLD_INDEX
  end

  def down
    columns = [:source_id, :source_type, :access_level]
    add_concurrent_index :members, columns, where: 'member_role_id IS NULL', name: OLD_INDEX
    remove_concurrent_index_by_name :members, NEW_INDEX
  end
end
