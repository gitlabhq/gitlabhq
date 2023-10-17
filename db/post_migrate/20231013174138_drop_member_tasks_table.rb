# frozen_string_literal: true

class DropMemberTasksTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_member_tasks_on_member_id_and_project_id'

  def up
    drop_table :member_tasks
  end

  def down
    create_table :member_tasks, id: :bigserial, force: :cascade do |t|
      t.bigint :member_id, null: false
      t.references :project, type: :bigint, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.integer :tasks, array: true, default: '{}', limit: 2, null: false
      t.index :member_id, name: 'index_member_tasks_on_member_id'
    end

    add_concurrent_foreign_key :member_tasks, :members, column: :member_id, on_delete: :cascade
    add_concurrent_index :member_tasks, [:member_id, :project_id], unique: true, name: INDEX_NAME
  end
end
