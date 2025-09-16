# frozen_string_literal: true

class DropDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      drop_table :duo_workflows_checkpoints, if_exists: true
    end
  end

  def down
    create_table :duo_workflows_checkpoints, if_not_exists: true do |t|
      t.bigint :workflow_id, null: false
      t.bigint :project_id, null: true
      t.timestamps_with_timezone null: false
      t.text :thread_ts, null: false, limit: 255
      t.text :parent_ts, null: true, limit: 255
      t.jsonb :checkpoint, null: false
      t.jsonb :metadata, null: false
      t.bigint :namespace_id, null: true

      t.index :namespace_id, name: :index_duo_workflows_checkpoints_on_namespace_id
      t.index :project_id, name: :index_duo_workflows_checkpoints_on_project_id
      t.index [:workflow_id, :thread_ts], unique: true, name: :index_duo_workflows_workflow_checkpoints_unique_thread
    end

    add_multi_column_not_null_constraint :duo_workflows_checkpoints, :project_id, :namespace_id
  end
end
