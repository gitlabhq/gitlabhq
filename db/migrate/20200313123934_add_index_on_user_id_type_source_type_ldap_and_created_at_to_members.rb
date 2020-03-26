# frozen_string_literal: true

class AddIndexOnUserIdTypeSourceTypeLdapAndCreatedAtToMembers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_members_on_user_id_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, [:user_id, :created_at], where: "ldap = TRUE AND type = 'GroupMember' AND source_type = 'Namespace'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
