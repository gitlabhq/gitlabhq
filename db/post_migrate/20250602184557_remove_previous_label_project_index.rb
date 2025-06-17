# frozen_string_literal: true

class RemovePreviousLabelProjectIndex < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  TABLE_NAME = :labels

  OLD_INDEX_COLUMNS = [:type, :project_id]
  OLD_INDEX_NAME = 'index_labels_on_type_and_project_id'

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: OLD_INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, OLD_INDEX_COLUMNS, name: OLD_INDEX_NAME
  end
end
