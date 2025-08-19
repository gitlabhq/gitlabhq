# frozen_string_literal: true

class AddTmpIndexOnLabelsWhereGroupProjectMissing < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_labels_on_group_project_missing'

  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_concurrent_index :labels,
      :id,
      name: INDEX_NAME,
      where: 'group_id IS NULL AND project_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :labels, INDEX_NAME
  end
end
