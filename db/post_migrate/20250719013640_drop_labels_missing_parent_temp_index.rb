# frozen_string_literal: true

class DropLabelsMissingParentTempIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_labels_on_group_project_missing'

  milestone '18.3'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :labels, INDEX_NAME
  end

  def down
    add_concurrent_index :labels,
      :id,
      name: INDEX_NAME,
      where: 'group_id IS NULL AND project_id IS NULL'
  end
end
