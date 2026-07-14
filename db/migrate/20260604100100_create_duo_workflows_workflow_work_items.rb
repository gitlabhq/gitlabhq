# frozen_string_literal: true

class CreateDuoWorkflowsWorkflowWorkItems < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_work_items

  def up
    create_table TABLE, if_not_exists: true do |t|
      t.bigint :workflow_id, null: false
      t.bigint :work_item_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      t.timestamps_with_timezone null: false
      t.integer :link_type, limit: 2, null: false

      t.index [:workflow_id, :work_item_id, :link_type], unique: true,
        name: 'index_duo_wf_wf_wi_on_workflow_id_and_work_item_id'
      t.index :work_item_id, name: 'index_duo_wf_wf_wi_on_work_item_id'
      t.index :project_id, name: 'index_duo_wf_wf_wi_on_project_id'
      t.index :namespace_id, name: 'index_duo_wf_wf_wi_on_namespace_id'
    end

    add_multi_column_not_null_constraint TABLE, :project_id, :namespace_id
  end

  def down
    drop_table TABLE
  end
end
