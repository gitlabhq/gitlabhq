# frozen_string_literal: true

class AddIndexOnMembersSourceAccessLevelMemberRole < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = "index_members_on_source_and_access_level_and_member_role"

  def up
    columns = [:source_id, :source_type, :access_level]
    add_concurrent_index(:members, columns, name: INDEX_NAME, where: 'member_role_id IS NULL')
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
