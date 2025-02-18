# frozen_string_literal: true

class DropMilestonesTempParentIndexBothMissing < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_milestones_on_project_group_both_missing'

  disable_ddl_transaction!
  milestone '17.9'

  def up
    remove_concurrent_index :milestones, :id, name: INDEX_NAME
  end

  def down
    add_concurrent_index :milestones, :id, name: INDEX_NAME, where: 'group_id IS NULL AND project_id IS NULL'
  end
end
