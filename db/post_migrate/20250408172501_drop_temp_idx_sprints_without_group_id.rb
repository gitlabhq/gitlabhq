# frozen_string_literal: true

class DropTempIdxSprintsWithoutGroupId < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_sprints_without_group_id'

  disable_ddl_transaction!
  milestone '17.11'

  def up
    remove_concurrent_index :sprints, :id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :sprints,
      :id,
      name: INDEX_NAME,
      where: 'group_id IS NULL'
  end
end
