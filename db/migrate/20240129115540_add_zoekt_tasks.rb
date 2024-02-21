# frozen_string_literal: true

class AddZoektTasks < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  OPTIONS = {
    primary_key: [:id, :partition_id],
    options: 'PARTITION BY LIST (partition_id)',
    if_not_exists: true
  }
  ZOEKT_NODE_ID_INDEX_NAME = 'index_zoekt_tasks_on_zoekt_node_id_and_state_and_perform_at'
  STATE_INDEX_NAME = 'index_zoekt_tasks_on_state'
  FAILED_STATE_ENUM = 255
  CONSTRAINT_NAME = 'c_zoekt_tasks_on_retries_left'
  CONSTRAINT_QUERY = <<~SQL
    (retries_left > 0) OR (retries_left = 0 AND state = #{FAILED_STATE_ENUM})
  SQL

  def change
    create_table :zoekt_tasks, **OPTIONS do |t|
      t.bigserial :id, null: false
      t.bigint :partition_id, null: false, default: 1
      t.bigint :zoekt_node_id, null: false
      t.bigint :zoekt_repository_id, null: false
      t.bigint :project_identifier, null: false # sharding key
      t.datetime_with_timezone :perform_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false
      t.integer :state, null: false, default: 0, limit: 2
      t.integer :task_type, null: false, limit: 2
      t.integer :retries_left, null: false, default: 5, limit: 2
      t.index :state, name: STATE_INDEX_NAME, using: :btree
      t.index :zoekt_repository_id
      t.index [:zoekt_node_id, :state, :perform_at], name: ZOEKT_NODE_ID_INDEX_NAME, using: :btree
      t.check_constraint CONSTRAINT_QUERY, name: CONSTRAINT_NAME
    end
  end
end
