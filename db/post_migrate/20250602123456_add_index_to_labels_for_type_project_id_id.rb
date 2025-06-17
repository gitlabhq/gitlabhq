# frozen_string_literal: true

class AddIndexToLabelsForTypeProjectIdId < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :labels

  NEW_INDEX_COLUMNS = [:type, :project_id, :id]
  NEW_INDEX_NAME = 'index_labels_on_type_project_id_and_id'

  def up
    add_concurrent_index TABLE_NAME, NEW_INDEX_COLUMNS, name: NEW_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: NEW_INDEX_NAME
  end
end
