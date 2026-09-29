# frozen_string_literal: true

class CreateDuoWorkflowsWorkflowWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  TABLE = :duo_workflows_workflow_workflows
  SELF_LINK_CONSTRAINT_NAME = 'check_duo_wf_wf_wf_no_self_link'

  def up
    create_table TABLE, if_not_exists: true do |t|
      t.bigint :workflow_id, null: false
      t.bigint :linked_workflow_id, null: false
      t.bigint :project_id
      t.bigint :namespace_id
      t.timestamps_with_timezone null: false
      t.integer :link_type, limit: 2, null: false

      t.index [:workflow_id, :linked_workflow_id, :link_type], unique: true,
        name: 'index_duo_wf_wf_wf_on_workflow_id_and_linked_workflow_id'
      t.index :linked_workflow_id, name: 'index_duo_wf_wf_wf_on_linked_workflow_id'
      t.index :project_id, name: 'index_duo_wf_wf_wf_on_project_id'
      t.index :namespace_id, name: 'index_duo_wf_wf_wf_on_namespace_id'

      # Both columns reference duo_workflows_workflows, so a row could otherwise claim a
      # workflow as its own restart source and make a restart chain cyclic.
      t.check_constraint 'workflow_id <> linked_workflow_id', name: SELF_LINK_CONSTRAINT_NAME
    end

    add_multi_column_not_null_constraint TABLE, :project_id, :namespace_id
  end

  def down
    drop_table TABLE
  end
end
