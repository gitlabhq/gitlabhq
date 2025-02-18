# frozen_string_literal: true

class AddDuoWorkflowsPendingWrites < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    create_table :duo_workflows_checkpoint_writes do |t|
      t.references :workflow, foreign_key: { to_table: :duo_workflows_workflows, on_delete: :cascade }, null: false,
        index: false
      t.bigint :project_id, null: false, index: true
      t.integer :idx, null: false
      t.text :thread_ts, null: false, limit: 255
      t.text :task, null: false, limit: 255
      t.text :channel, null: false, limit: 255
      t.text :write_type, null: false, limit: 255
      t.text :data, null: false, limit: 10000

      t.index [:workflow_id, :thread_ts], name: 'index_duo_workflows_checkpoint_writes_thread_ts'
    end
  end

  def down
    drop_table :duo_workflows_checkpoint_writes
  end
end
