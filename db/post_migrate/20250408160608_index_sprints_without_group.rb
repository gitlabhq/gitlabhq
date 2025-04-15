# frozen_string_literal: true

class IndexSprintsWithoutGroup < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_sprints_without_group_id'

  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_index :sprints,
      :id,
      name: INDEX_NAME,
      where: 'group_id IS NULL'
  end

  def down
    remove_concurrent_index :sprints, :id, name: INDEX_NAME
  end
end
