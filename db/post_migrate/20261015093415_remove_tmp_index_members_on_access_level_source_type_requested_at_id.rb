# frozen_string_literal: true

class RemoveTmpIndexMembersOnAccessLevelSourceTypeRequestedAtId < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!

  milestone '19.6'

  INDEX_NAME = 'tmp_idx_members_on_access_level_source_type_requested_at_id'

  def up
    remove_concurrent_index_by_name(:members, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :members,
      :id,
      where: "access_level = 5 AND source_type = 'Namespace' AND requested_at IS NULL",
      name: INDEX_NAME
    )
  end
end
