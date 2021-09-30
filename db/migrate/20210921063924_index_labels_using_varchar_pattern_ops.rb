# frozen_string_literal: true

class IndexLabelsUsingVarcharPatternOps < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  NEW_TITLE_INDEX_NAME = 'index_labels_on_title_varchar'
  NEW_PROJECT_ID_TITLE_INDEX_NAME = 'index_labels_on_project_id_and_title_varchar_unique'
  NEW_GROUP_ID_TITLE_INDEX_NAME = 'index_labels_on_group_id_and_title_varchar_unique'
  NEW_GROUP_ID_INDEX_NAME = 'index_labels_on_group_id'

  OLD_TITLE_INDEX_NAME = 'index_labels_on_title'
  OLD_PROJECT_ID_TITLE_INDEX_NAME = 'index_labels_on_project_id_and_title_unique'
  OLD_GROUP_ID_TITLE_INDEX_NAME = 'index_labels_on_group_id_and_title_unique'
  OLD_GROUP_ID_PROJECT_ID_TITLE_INDEX_NAME = 'index_labels_on_group_id_and_project_id_and_title'

  def up
    add_concurrent_index :labels, :title, order: { title: :varchar_pattern_ops }, name: NEW_TITLE_INDEX_NAME
    add_concurrent_index :labels, [:project_id, :title], where: "labels.group_id IS NULL", unique: true, order: { title: :varchar_pattern_ops }, name: NEW_PROJECT_ID_TITLE_INDEX_NAME
    add_concurrent_index :labels, [:group_id, :title], where: "labels.project_id IS NULL", unique: true, order: { title: :varchar_pattern_ops }, name: NEW_GROUP_ID_TITLE_INDEX_NAME
    add_concurrent_index :labels, :group_id, name: NEW_GROUP_ID_INDEX_NAME

    remove_concurrent_index_by_name :labels, OLD_TITLE_INDEX_NAME
    remove_concurrent_index_by_name :labels, OLD_PROJECT_ID_TITLE_INDEX_NAME
    remove_concurrent_index_by_name :labels, OLD_GROUP_ID_TITLE_INDEX_NAME
    remove_concurrent_index_by_name :labels, OLD_GROUP_ID_PROJECT_ID_TITLE_INDEX_NAME
  end

  def down
    add_concurrent_index :labels, :title, name: OLD_TITLE_INDEX_NAME
    add_concurrent_index :labels, [:project_id, :title], where: "labels.group_id IS NULL", unique: true, name: OLD_PROJECT_ID_TITLE_INDEX_NAME
    add_concurrent_index :labels, [:group_id, :title], where: "labels.project_id IS NULL", unique: true, name: OLD_GROUP_ID_TITLE_INDEX_NAME
    add_concurrent_index :labels, [:group_id, :project_id, :title], unique: true, name: OLD_GROUP_ID_PROJECT_ID_TITLE_INDEX_NAME

    remove_concurrent_index_by_name :labels, NEW_TITLE_INDEX_NAME
    remove_concurrent_index_by_name :labels, NEW_PROJECT_ID_TITLE_INDEX_NAME
    remove_concurrent_index_by_name :labels, NEW_GROUP_ID_TITLE_INDEX_NAME
    remove_concurrent_index_by_name :labels, NEW_GROUP_ID_INDEX_NAME
  end
end
