# frozen_string_literal: true

class AddTempIndexToLabelsWithGroupAndProject < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_labels_with_group_and_project'

  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_index :labels, :id, name: INDEX_NAME, where: 'group_id IS NOT NULL AND project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :labels, :id, name: INDEX_NAME
  end
end
