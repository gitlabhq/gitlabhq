# frozen_string_literal: true

class AddIndexMemberRoleOnBaseAccessLevel < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.7'

  INDEX_NAME = :idx_member_roles_on_base_access_level
  TABLE_NAME = :member_roles

  def up
    add_concurrent_index TABLE_NAME, :base_access_level, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
