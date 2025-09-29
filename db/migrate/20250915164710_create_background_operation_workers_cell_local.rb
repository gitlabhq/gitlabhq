# frozen_string_literal: true

class CreateBackgroundOperationWorkersCellLocal < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.5'

  disable_ddl_transaction!

  def up
    opts = {
      if_not_exists: true,
      primary_key: [:partition, :id],
      options: 'PARTITION BY LIST (partition)'
    }

    create_table(:background_operation_workers_cell_local, **opts) do |t|
      t.bigserial :id
      t.bigint :total_tuple_count
      t.bigint :partition, null: false, default: 1
      t.timestamptz :started_at
      t.timestamptz :on_hold_until
      t.timestamptz :created_at, null: false
      t.timestamptz :finished_at
      t.integer :batch_size, null: false
      t.integer :sub_batch_size, null: false
      t.integer :pause_ms, null: false, default: 100
      t.integer :max_batch_size
      t.integer :priority, null: false, limit: 2, default: 0
      t.integer :status, null: false, limit: 2, default: 0
      t.integer :interval, null: false, limit: 2
      t.text :job_class_name, null: false, limit: 100
      t.text :batch_class_name, null: false, limit: 100
      t.text :table_name, null: false, limit: 63
      t.text :column_name, null: false, limit: 63
      t.text :gitlab_schema, null: false, limit: 255
      t.jsonb :job_arguments, default: '[]'
      t.jsonb :min_cursor
      t.jsonb :max_cursor
      t.jsonb :next_min_cursor
    end

    add_indexes
    add_constraints
  end

  def down
    drop_table(:background_operation_workers_cell_local, if_exists: true)
  end

  private

  def add_indexes
    add_concurrent_partitioned_index(
      :background_operation_workers_cell_local,
      :status,
      name: 'index_bow_cell_local_by_status'
    )
    add_concurrent_partitioned_index(
      :background_operation_workers_cell_local,
      [:partition, :job_class_name, :table_name, :column_name, :job_arguments],
      unique: true,
      name: 'index_bow_cell_local_on_unique_configuration'
    )
  end

  def add_constraints
    add_check_constraint(
      :background_operation_workers_cell_local,
      '(batch_size >= sub_batch_size)',
      check_constraint_name(:background_operation_workers_cell_local, 'batch_size', 'greater_than_sub_batch_size')
    )
    add_check_constraint(
      :background_operation_workers_cell_local,
      '(sub_batch_size > 0)',
      check_constraint_name(:background_operation_workers_cell_local, 'sub_batch_size', 'greater_than_zero')
    )
    add_check_constraint(
      :background_operation_workers_cell_local,
      "jsonb_typeof(min_cursor) = 'array' AND jsonb_typeof(max_cursor) = 'array'",
      check_constraint_name(:background_operation_workers_cell_local, 'cursors', 'jsonb_array')
    )
    add_check_constraint(
      :background_operation_workers_cell_local,
      'num_nonnulls(min_cursor, max_cursor) = 2',
      check_constraint_name(:background_operation_workers_cell_local, 'cursors', 'not_null')
    )
  end
end
