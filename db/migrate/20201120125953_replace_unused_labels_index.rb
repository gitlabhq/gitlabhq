# frozen_string_literal: true

class ReplaceUnusedLabelsIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  NEW_INDEX_NAME = 'index_labels_on_group_id_and_title_with_null_project_id'
  OLD_INDEX_NAME = 'index_labels_on_group_id_and_title'

  def up
    add_concurrent_index :labels, [:group_id, :title], where: 'project_id IS NULL', name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :labels, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :labels, [:group_id, :title], where: 'project_id = NULL::integer', name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :labels, NEW_INDEX_NAME
  end
end
