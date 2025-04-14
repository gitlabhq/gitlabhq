# frozen_string_literal: true

class DropTempIndexesFromIssuesOnCorrectWorkItemTypeId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  INDEX_NAME1 = 'tmp_idx_issues_on_correct_type_project_created_at_state'
  INDEX_NAME2 = 'tmp_idx_issues_on_project_correct_type_closed_at_where_closed'
  INDEX_NAME3 = 'tmp_idx_issues_on_project_health_id_asc_state_correct_type'
  INDEX_NAME4 = 'tmp_idx_issues_on_project_health_id_desc_state_correct_type'

  def up
    remove_concurrent_index_by_name :issues, INDEX_NAME1
    remove_concurrent_index_by_name :issues, INDEX_NAME2
    remove_concurrent_index_by_name :issues, INDEX_NAME3
    remove_concurrent_index_by_name :issues, INDEX_NAME4
  end

  def down
    add_concurrent_index :issues,
      [:correct_work_item_type_id, :project_id, :created_at, :state_id],
      name: INDEX_NAME1

    add_concurrent_index :issues,
      [:project_id, :correct_work_item_type_id, :closed_at],
      where: 'state_id = 2',
      name: INDEX_NAME2

    add_concurrent_index :issues,
      [:project_id, :health_status, :id, :state_id, :correct_work_item_type_id],
      order: { health_status: 'ASC NULLS LAST', id: :desc },
      name: INDEX_NAME3

    add_concurrent_index :issues,
      [:project_id, :health_status, :id, :state_id, :correct_work_item_type_id],
      order: { health_status: 'DESC NULLS LAST', id: :desc },
      name: INDEX_NAME4
  end
end
