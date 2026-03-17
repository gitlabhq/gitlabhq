# frozen_string_literal: true

class CreateAiActiveContextTasks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  def up
    create_table :ai_active_context_tasks, if_not_exists: true do |t|
      t.timestamps_with_timezone null: false
      t.bigint :connection_id, null: false
      t.bigint :depends_on_id
      t.datetime_with_timezone :started_at
      t.datetime_with_timezone :completed_at

      t.integer :status, limit: 2, null: false, default: 0
      t.integer :retries_left, limit: 2, null: false, default: 3

      t.text  :name, null: false
      t.text  :error_message
      t.jsonb :params, null: false, default: {}
    end

    add_text_limit :ai_active_context_tasks, :name, 255
    add_text_limit :ai_active_context_tasks, :error_message, 1024

    add_check_constraint :ai_active_context_tasks,
      '(retries_left > 0) OR ((retries_left = 0) AND (status = 255))',
      'c_ai_active_context_tasks_on_retries_left'

    add_index :ai_active_context_tasks, :connection_id
    add_index :ai_active_context_tasks, :depends_on_id

    add_concurrent_foreign_key :ai_active_context_tasks,
      :ai_active_context_connections,
      column: :connection_id,
      on_delete: :cascade

    add_concurrent_foreign_key :ai_active_context_tasks,
      :ai_active_context_tasks,
      column: :depends_on_id,
      on_delete: :nullify
  end

  def down
    drop_table :ai_active_context_tasks
  end
end
