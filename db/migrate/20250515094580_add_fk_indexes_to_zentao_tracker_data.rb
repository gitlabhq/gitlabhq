# frozen_string_literal: true

class AddFkIndexesToZentaoTrackerData < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  TABLE_NAME = :zentao_tracker_data
  PROJECT_ID_INDEX_NAME = 'index_zentao_tracker_data_on_project_id'
  GROUP_ID_INDEX_NAME = 'index_zentao_tracker_data_on_group_id'
  ORGANIZATION_ID_INDEX_NAME = 'index_zentao_tracker_data_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :project_id, name: PROJECT_ID_INDEX_NAME
    add_concurrent_index TABLE_NAME, :group_id, name: GROUP_ID_INDEX_NAME
    add_concurrent_index TABLE_NAME, :organization_id, name: ORGANIZATION_ID_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, name: PROJECT_ID_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, name: GROUP_ID_INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, name: ORGANIZATION_ID_INDEX_NAME
  end
end
