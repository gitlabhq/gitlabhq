# frozen_string_literal: true

class AddTmpIndexOnMembersForActiveGroupMembers < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  INDEX_NAME = :tmp_idx_members_for_active_group_members

  CONSTRAINT = "source_type = 'Namespace' AND state = 0 AND user_id IS NOT NULL AND requested_at IS NULL"

  def up
    add_concurrent_index :members, :id, where: CONSTRAINT, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :members, INDEX_NAME
  end
end
