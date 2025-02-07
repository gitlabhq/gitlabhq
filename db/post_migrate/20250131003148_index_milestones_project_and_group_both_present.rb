# frozen_string_literal: true

class IndexMilestonesProjectAndGroupBothPresent < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'tmp_idx_milestones_on_project_group_both_present'

  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_concurrent_index :milestones, :id, name: INDEX_NAME, where: 'group_id IS NOT NULL AND project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :milestones, :id, name: INDEX_NAME
  end
end
