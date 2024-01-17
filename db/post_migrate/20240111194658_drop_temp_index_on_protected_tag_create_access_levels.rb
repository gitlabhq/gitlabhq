# frozen_string_literal: true

class DropTempIndexOnProtectedTagCreateAccessLevels < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  INDEX_NAME = 'tmp_idx_protected_tag_create_access_levels_on_id_with_group'

  def up
    remove_concurrent_index_by_name(
      :protected_tag_create_access_levels,
      INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      :protected_tag_create_access_levels,
      %i[id],
      where: 'group_id IS NOT NULL',
      name: INDEX_NAME
    )
  end
end
